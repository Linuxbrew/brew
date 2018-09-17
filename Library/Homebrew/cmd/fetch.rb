#:  * `fetch` [`--force`] [`--retry`] [`-v`] [`--devel`|`--HEAD`] [`--deps`] [`--build-from-source`|`--force-bottle`] <formulae>:
#:    Download the source packages for the given <formulae>.
#:    For tarballs, also print SHA-256 checksums.
#:
#:    If `--HEAD` or `--devel` is passed, fetch that version instead of the
#:    stable version.
#:
#:    If `-v` is passed, do a verbose VCS checkout, if the URL represents a VCS.
#:    This is useful for seeing if an existing VCS cache has been updated.
#:
#:    If `--force` (or `-f`) is passed, remove a previously cached version and re-fetch.
#:
#:    If `--retry` is passed, retry if a download fails or re-download if the
#:    checksum of a previously cached version no longer matches.
#:
#:    If `--deps` is passed, also download dependencies for any listed <formulae>.
#:
#:    If `--build-from-source` (or `-s`) is passed, download the source rather than a
#:    bottle.
#:
#:    If `--force-bottle` is passed, download a bottle if it exists for the
#:    current or newest version of macOS, even if it would not be used during
#:    installation.

require "formula"
require "fetch"

module Homebrew
  module_function

  def fetch
    raise FormulaUnspecifiedError if ARGV.named.empty?

    if ARGV.include? "--deps"
      bucket = []
      ARGV.formulae.each do |f|
        bucket << f
        bucket.concat f.recursive_dependencies.map(&:to_formula)
      end
      bucket.uniq!
    else
      bucket = ARGV.formulae
    end

    puts "Fetching: #{bucket * ", "}" if bucket.size > 1
    bucket.each do |f|
      f.print_tap_action verb: "Fetching"

      fetched_bottle = false
      if Fetch.fetch_bottle?(f)
        begin
          fetch_formula(f.bottle)
        rescue Interrupt
          raise
        rescue => e
          raise if ARGV.homebrew_developer?

          fetched_bottle = false
          onoe e.message
          opoo "Bottle fetch failed: fetching the source."
        else
          fetched_bottle = true
        end
      end

      next if fetched_bottle

      fetch_formula(f)

      f.resources.each do |r|
        fetch_resource(r)
        r.patches.each { |p| fetch_patch(p) if p.external? }
      end

      f.patchlist.each { |p| fetch_patch(p) if p.external? }
    end
  end

  def fetch_resource(r)
    puts "Resource: #{r.name}"
    fetch_fetchable r
  rescue ChecksumMismatchError => e
    retry if retry_fetch? r
    opoo "Resource #{r.name} reports different #{e.hash_type}: #{e.expected}"
  end

  def fetch_formula(f)
    fetch_fetchable f
  rescue ChecksumMismatchError => e
    retry if retry_fetch? f
    opoo "Formula reports different #{e.hash_type}: #{e.expected}"
  end

  def fetch_patch(p)
    fetch_fetchable p
  rescue ChecksumMismatchError => e
    Homebrew.failed = true
    opoo "Patch reports different #{e.hash_type}: #{e.expected}"
  end

  def retry_fetch?(f)
    @fetch_failed ||= Set.new
    if ARGV.include?("--retry") && @fetch_failed.add?(f)
      ohai "Retrying download"
      f.clear_cache
      true
    else
      Homebrew.failed = true
      false
    end
  end

  def fetch_fetchable(f)
    f.clear_cache if ARGV.force?

    already_fetched = f.cached_download.exist?

    begin
      download = f.fetch
    rescue DownloadError
      retry if retry_fetch? f
      raise
    end

    return unless download.file?

    puts "Downloaded to: #{download}" unless already_fetched
    puts Checksum::TYPES.map { |t| "#{t.to_s.upcase}: #{download.send(t)}" }

    f.verify_download_integrity(download)
  end
end
