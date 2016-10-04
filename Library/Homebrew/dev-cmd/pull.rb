#: `pull` [`--bottle`] [`--bump`] [`--clean`] [`--ignore-whitespace`] [`--resolve`] [`--branch-okay`] [`--no-pbcopy`] [`--no-publish`] <patch-source> [<patch-source>]
#:
#:    Gets a patch from a GitHub commit or pull request and applies it to Homebrew.
#:    Optionally, installs the formulae changed by the patch.
#:
#:    Each <patch-source> may be one of:
#:      * The ID number of a PR (Pull Request) in the homebrew/core GitHub
#:        repository
#:      * The URL of a PR on GitHub, using either the web page or API URL
#:        formats. In this form, the PR may be on Homebrew/brew,
#:        Homebrew/homebrew-core or any tap.
#:      * The URL of a commit on GitHub
#:      * A "http://bot.brew.sh/job/..." string specifying a testing job ID
#:
#:   If `--bottle` was passed, handle bottles, pulling the bottle-update
#:   commit and publishing files on Bintray.
#:   If `--bump` was passed, for one-formula PRs, automatically reword
#:   commit message to our preferred format.
#:   If `--clean` was passed, do not rewrite or otherwise modify the
#:   commits found in the pulled PR.
#:   If `--ignore-whitespace` was passed, silently ignore whitespace
#:   discrepancies when applying diffs.
#:   If `--resolve` was passed, when a patch fails to apply, leave in
#:   progress and allow user to
#:                  resolve, instead of aborting.
#:   If `--branch-okay` was passed, do not warn if pulling to a branch
#:   besides master (useful for testing).
#:   If `--no-pbcopy` was passed, do not copy anything to the system
#    clipboard.
#:   If `--no-publish` was passed, do not publish bottles to Bintray.

require "net/http"
require "net/https"
require "utils"
require "utils/json"
require "formula"
require "formulary"
require "tap"
require "version"
require "pkg_version"

module Homebrew
  module_function

  def pull
    odie "You meant `git pull --rebase`." if ARGV[0] == "--rebase"

    if ARGV.named.empty?
      odie "This command requires at least one argument containing a URL or pull request number"
    end

    do_bump = ARGV.include?("--bump") && !ARGV.include?("--clean")

    # Formulae with affected bottles that were published
    bintray_published_formulae = []
    tap = nil

    ARGV.named.each do |arg|
      if arg.to_i > 0
        issue = arg
        url = "https://github.com/Homebrew/homebrew-core/pull/#{arg}"
        tap = CoreTap.instance
      elsif (testing_match = arg.match %r{/job/Homebrew.*Testing/(\d+)/})
        tap = ARGV.value("tap")
        tap = if tap && tap.start_with?("homebrew/")
          Tap.fetch("homebrew", tap.strip_prefix("homebrew/"))
        elsif tap
          odie "Tap option did not start with \"homebrew/\": #{tap}"
        else
          CoreTap.instance
        end
        _, testing_job = *testing_match
        url = "https://github.com/Homebrew/homebrew-#{tap.repo}/compare/master...BrewTestBot:testing-#{testing_job}"
        odie "Testing URLs require `--bottle`!" unless ARGV.include?("--bottle")
      elsif (api_match = arg.match HOMEBREW_PULL_API_REGEX)
        _, user, repo, issue = *api_match
        url = "https://github.com/#{user}/#{repo}/pull/#{issue}"
        tap = Tap.fetch(user, repo) if repo.start_with?("homebrew-")
      elsif (url_match = arg.match HOMEBREW_PULL_OR_COMMIT_URL_REGEX)
        url, user, repo, issue = *url_match
        tap = Tap.fetch(user, repo) if repo.start_with?("homebrew-")
      else
        odie "Not a GitHub pull request or commit: #{arg}"
      end

      if !testing_job && ARGV.include?("--bottle") && issue.nil?
        odie "No pull request detected!"
      end

      if tap
        tap.install unless tap.installed?
        Dir.chdir tap.path
      else
        Dir.chdir HOMEBREW_REPOSITORY
      end

      # The cache directory seems like a good place to put patches.
      HOMEBREW_CACHE.mkpath

      # Store current revision and branch
      orig_revision = `git rev-parse --short HEAD`.strip
      branch = `git symbolic-ref --short HEAD`.strip

      unless branch == "master" || ARGV.include?("--clean") || ARGV.include?("--branch-okay")
        opoo "Current branch is #{branch}: do you need to pull inside master?"
      end

      patch_puller = PatchPuller.new(url)
      patch_puller.fetch_patch
      patch_changes = files_changed_in_patch(patch_puller.patchpath, tap)

      is_bumpable = patch_changes[:formulae].length == 1 && patch_changes[:others].empty?
      if do_bump
        odie "No changed formulae found to bump" if patch_changes[:formulae].empty?
        if patch_changes[:formulae].length > 1
          odie "Can only bump one changed formula; bumped #{patch_changes[:formulae]}"
        end
        odie "Can not bump if non-formula files are changed" unless patch_changes[:others].empty?
      end
      if is_bumpable
        old_versions = current_versions_from_info_external(patch_changes[:formulae].first)
      end
      patch_puller.apply_patch

      changed_formulae_names = []

      if tap
        Utils.popen_read(
          "git", "diff-tree", "-r", "--name-only",
          "--diff-filter=AM", orig_revision, "HEAD", "--", tap.formula_dir.to_s
        ).each_line do |line|
          next unless line.end_with? ".rb\n"
          name = "#{tap.name}/#{File.basename(line.chomp, ".rb")}"
          changed_formulae_names << name
        end
      end

      fetch_bottles = false
      changed_formulae_names.each do |name|
        next if ENV["HOMEBREW_DISABLE_LOAD_FORMULA"]

        begin
          f = Formula[name]
        # Make sure we catch syntax errors.
        rescue Exception
          next
        end

        if ARGV.include? "--bottle"
          if f.bottle_unneeded?
            ohai "#{f}: skipping unneeded bottle."
          elsif f.bottle_disabled?
            ohai "#{f}: skipping disabled bottle: #{f.bottle_disable_reason}"
          else
            fetch_bottles = true
          end
        else
          next unless f.bottle_defined?
          opoo "#{f.full_name} has a bottle: do you need to update it with --bottle?"
        end
      end

      orig_message = message = `git log HEAD^.. --format=%B`
      if issue && !ARGV.include?("--clean")
        ohai "Patch closes issue ##{issue}"
        close_message = "Closes ##{issue}."
        # If this is a pull request, append a close message.
        message += "\n#{close_message}" unless message.include? close_message
      end

      if changed_formulae_names.empty?
        odie "cannot bump: no changed formulae found after applying patch" if do_bump
        is_bumpable = false
      end

      is_bumpable = false if ARGV.include?("--clean")
      is_bumpable = false if ENV["HOMEBREW_DISABLE_LOAD_FORMULA"]

      if is_bumpable
        formula = Formula[changed_formulae_names.first]
        new_versions = current_versions_from_info_external(patch_changes[:formulae].first)
        orig_subject = message.empty? ? "" : message.lines.first.chomp
        bump_subject = subject_for_bump(formula, old_versions, new_versions)
        if do_bump
          odie "No version changes found for #{formula.name}" if bump_subject.nil?
          unless orig_subject == bump_subject
            ohai "New bump commit subject: #{bump_subject}"
            pbcopy bump_subject unless ARGV.include? "--no-pbcopy"
            message = "#{bump_subject}\n\n#{message}"
          end
        elsif bump_subject != orig_subject && !bump_subject.nil?
          opoo "Nonstandard bump subject: #{orig_subject}"
          opoo "Subject should be: #{bump_subject}"
        end
      end

      if message != orig_message && !ARGV.include?("--clean")
        safe_system "git", "commit", "--amend", "--signoff", "--allow-empty", "-q", "-m", message
      end

      # Bottles: Pull bottle block commit and publish bottle files on Bintray
      if fetch_bottles
        bottle_commit_url = if testing_job
          bottle_branch = "testing-bottle-#{testing_job}"
          url
        else
          bottle_branch = "pull-bottle-#{issue}"
          "https://github.com/BrewTestBot/homebrew-#{tap.repo}/compare/homebrew:master...pr-#{issue}"
        end

        curl "--silent", "--fail", "-o", "/dev/null", "-I", bottle_commit_url

        safe_system "git", "checkout", "--quiet", "-B", bottle_branch, orig_revision
        pull_patch bottle_commit_url, "bottle commit"
        safe_system "git", "rebase", "--quiet", branch
        safe_system "git", "checkout", "--quiet", branch
        safe_system "git", "merge", "--quiet", "--ff-only", "--no-edit", bottle_branch
        safe_system "git", "branch", "--quiet", "-D", bottle_branch

        # Publish bottles on Bintray
        unless ARGV.include? "--no-publish"
          published = publish_changed_formula_bottles(tap, changed_formulae_names)
          bintray_published_formulae.concat(published)
        end
      end

      ohai "Patch changed:"
      safe_system "git", "diff-tree", "-r", "--stat", orig_revision, "HEAD"
    end

    # Verify bintray publishing after all patches have been applied
    bintray_published_formulae.uniq!
    verify_bintray_published(bintray_published_formulae)
  end

  def force_utf8!(str)
    str.force_encoding("UTF-8") if str.respond_to?(:force_encoding)
  end

  def publish_changed_formula_bottles(_tap, changed_formulae_names)
    if ENV["HOMEBREW_DISABLE_LOAD_FORMULA"]
      raise "Need to load formulae to publish them!"
    end

    published = []
    bintray_creds = { user: ENV["BINTRAY_USER"], key: ENV["BINTRAY_KEY"] }
    if bintray_creds[:user] && bintray_creds[:key]
      changed_formulae_names.each do |name|
        f = Formula[name]
        next if f.bottle_unneeded? || f.bottle_disabled?
        ohai "Publishing on Bintray: #{f.name} #{f.pkg_version}"
        publish_bottle_file_on_bintray(f, bintray_creds)
        published << f.full_name
      end
    else
      opoo "You must set BINTRAY_USER and BINTRAY_KEY to add or update bottles on Bintray!"
    end
    published
  end

  def pull_patch(url, description = nil)
    PatchPuller.new(url, description).pull_patch
  end

  class PatchPuller
    attr_reader :base_url
    attr_reader :patch_url
    attr_reader :patchpath

    def initialize(url, description = nil)
      @base_url = url
      # GitHub provides commits/pull-requests raw patches using this URL.
      @patch_url = url + ".patch"
      @patchpath = HOMEBREW_CACHE + File.basename(patch_url)
      @description = description
    end

    def pull_patch
      fetch_patch
      apply_patch
    end

    def fetch_patch
      extra_msg = @description ? "(#{@description})" : nil
      ohai "Fetching patch #{extra_msg}"
      puts "Patch: #{patch_url}"
      curl patch_url, "-s", "-o", patchpath
    end

    def apply_patch
      # Applies a patch previously downloaded with fetch_patch()
      # Deletes the patch file as a side effect, regardless of success

      ohai "Applying patch"
      patch_args = []
      # Normally we don't want whitespace errors, but squashing them can break
      # patches so an option is provided to skip this step.
      if ARGV.include?("--ignore-whitespace") || ARGV.include?("--clean")
        patch_args << "--whitespace=nowarn"
      else
        patch_args << "--whitespace=fix"
      end

      # Fall back to three-way merge if patch does not apply cleanly
      patch_args << "-3"
      patch_args << patchpath

      begin
        safe_system "git", "am", *patch_args
      rescue ErrorDuringExecution
        if ARGV.include? "--resolve"
          odie "Patch failed to apply: try to resolve it."
        else
          system "git", "am", "--abort"
          odie "Patch failed to apply: aborted."
        end
      ensure
        patchpath.unlink
      end
    end
  end

  # List files changed by a patch, partitioned in to those that are (probably)
  # formula definitions, and those which aren't. Only applies to patches on
  # Homebrew core or taps, based simply on relative pathnames of affected files.
  def files_changed_in_patch(patchfile, tap)
    files = []
    formulae = []
    others = []
    File.foreach(patchfile) do |line|
      files << $1 if line =~ %r{^\+\+\+ b/(.*)}
    end
    files.each do |file|
      if tap && tap.formula_file?(file)
        formula_name = File.basename(file, ".rb")
        formulae << formula_name unless formulae.include?(formula_name)
      else
        others << file
      end
    end
    { files: files, formulae: formulae, others: others }
  end

  # Get current formula versions without loading formula definition in this process
  # Returns info as a hash (type => version), for pull.rb's internal use
  # Uses special key :nonexistent => true for nonexistent formulae
  def current_versions_from_info_external(formula_name)
    info = FormulaInfoFromJson.lookup(formula_name)
    versions = {}
    if info
      [:stable, :devel, :head].each do |spec_type|
        versions[spec_type] = info.version(spec_type)
      end
    else
      versions[:nonexistent] = true
    end
    versions
  end

  def subject_for_bump(formula, old, new)
    if old[:nonexistent]
      # New formula
      headline_ver = if new[:stable]
        new[:stable]
      elsif new[:devel]
        new[:devel]
      else
        new[:head]
      end
      subject = "#{formula.name} #{headline_ver} (new formula)"
    else
      # Update to existing formula
      subject_strs = []
      formula_name_str = formula.name
      if old[:stable] != new[:stable]
        if new[:stable].nil?
          subject_strs << "remove stable"
          formula_name_str += ":" # just for cosmetics
        else
          subject_strs << formula.version.to_s
        end
      end
      if old[:devel] != new[:devel]
        if new[:devel].nil?
          # Only bother mentioning if there's no accompanying stable change
          if !new[:stable].nil? && old[:stable] == new[:stable]
            subject_strs << "remove devel"
            formula_name_str += ":" # just for cosmetics
          end
        else
          subject_strs << "#{formula.devel.version} (devel)"
        end
      end
      subject = subject_strs.empty? ? nil : "#{formula_name_str} #{subject_strs.join(", ")}"
    end
    subject
  end

  def pbcopy(text)
    Utils.popen_write("pbcopy") { |io| io.write text }
  end

  # Publishes the current bottle files for a given formula to Bintray
  def publish_bottle_file_on_bintray(f, creds)
    repo = Utils::Bottles::Bintray.repository(f.tap)
    package = Utils::Bottles::Bintray.package(f.name)
    info = FormulaInfoFromJson.lookup(f.name)
    if info.nil?
      raise "Failed publishing bottle: failed reading formula info for #{f.full_name}"
    end
    version = info.pkg_version
    curl "-w", '\n', "--silent", "--fail",
         "-u#{creds[:user]}:#{creds[:key]}", "-X", "POST",
         "-H", "Content-Type: application/json",
         "-d", '{"publish_wait_for_secs": 0}',
         "https://api.bintray.com/content/homebrew/#{repo}/#{package}/#{version}/publish"
  end

  # Formula info drawn from an external "brew info --json" call
  class FormulaInfoFromJson
    # The whole info structure parsed from the JSON
    attr_accessor :info

    def initialize(info)
      @info = info
    end

    # Looks up formula on disk and reads its info
    # Returns nil if formula is absent or if there was an error reading it
    def self.lookup(name)
      json = Utils.popen_read(HOMEBREW_BREW_FILE, "info", "--json=v1", name)

      return nil unless $?.success?

      Homebrew.force_utf8!(json)
      FormulaInfoFromJson.new(Utils::JSON.load(json)[0])
    end

    def bottle_tags
      return [] unless info["bottle"]["stable"]
      info["bottle"]["stable"]["files"].keys
    end

    def bottle_info(my_bottle_tag = Utils::Bottles.tag)
      tag_s = my_bottle_tag.to_s
      return nil unless info["bottle"]["stable"]
      btl_info = info["bottle"]["stable"]["files"][tag_s]
      return nil unless btl_info
      BottleInfo.new(btl_info["url"], btl_info["sha256"])
    end

    def bottle_info_any
      bottle_info(any_bottle_tag)
    end

    def any_bottle_tag
      tag = Utils::Bottles.tag
      # Prefer native bottles as a convenience for download caching
      bottle_tags.include?(tag) ? tag : bottle_tags.first
    end

    def version(spec_type)
      version_str = info["versions"][spec_type.to_s]
      version_str && Version.create(version_str)
    end

    def pkg_version(spec_type = :stable)
      PkgVersion.new(version(spec_type), revision)
    end

    def revision
      info["revision"]
    end
  end

  # Bottle info as used internally by pull, with alternate platform support
  class BottleInfo
    # URL of bottle as string
    attr_accessor :url
    # Expected SHA256 as string
    attr_accessor :sha256

    def initialize(url, sha256)
      @url = url
      @sha256 = sha256
    end
  end

  # Verifies that formulae have been published on Bintray by downloading a bottle file
  # for each one. Blocks until the published files are available.
  # Raises an error if the verification fails.
  # This does not currently work for `brew pull`, because it may have cached the old
  # version of a formula.
  def verify_bintray_published(formulae_names)
    return if formulae_names.empty?

    if ENV["HOMEBREW_DISABLE_LOAD_FORMULA"]
      raise "Need to load formulae to verify their publication!"
    end

    ohai "Verifying bottles published on Bintray"
    formulae = formulae_names.map { |n| Formula[n] }
    max_retries = 300 # shared among all bottles
    poll_retry_delay_seconds = 2

    HOMEBREW_CACHE.cd do
      formulae.each do |f|
        retry_count = 0
        wrote_dots = false
        # Choose arbitrary bottle just to get the host/port for Bintray right
        jinfo = FormulaInfoFromJson.lookup(f.full_name)
        unless jinfo
          opoo "Cannot publish bottle: Failed reading info for formula #{f.full_name}"
          next
        end
        bottle_info = jinfo.bottle_info(jinfo.bottle_tags.first)
        unless bottle_info
          opoo "No bottle defined in formula #{f.full_name}"
          next
        end

        # Poll for publication completion using a quick partial HEAD, to avoid spurious error messages
        # 401 error is normal while file is still in async publishing process
        url = URI(bottle_info.url)
        puts "Verifying bottle: #{File.basename(url.path)}"
        http = Net::HTTP.new(url.host, url.port)
        http.use_ssl = true
        retry_count = 0
        http.start do
          loop do
            req = Net::HTTP::Head.new bottle_info.url
            req.initialize_http_header "User-Agent" => HOMEBREW_USER_AGENT_RUBY
            res = http.request req
            break if res.is_a?(Net::HTTPSuccess)

            unless res.is_a?(Net::HTTPClientError)
              raise "Failed to find published #{f} bottle at #{url} (#{res.code} #{res.message})!"
            end

            if retry_count >= max_retries
              raise "Failed to find published #{f} bottle at #{url}!"
            end
            print(wrote_dots ? "." : "Waiting on Bintray.")
            wrote_dots = true
            sleep poll_retry_delay_seconds
            retry_count += 1
          end
        end

        # Actual download and verification
        # We do a retry on this, too, because sometimes the external curl will fail even
        # when the prior HEAD has succeeded.
        puts "\n" if wrote_dots
        filename = File.basename(url.path)
        curl_retry_delay_seconds = 4
        max_curl_retries = 1
        retry_count = 0
        # We're in the cache; make sure to force re-download
        loop do
          begin
            curl url, "-o", filename
            break
          rescue
            if retry_count >= max_curl_retries
              raise "Failed to download #{f} bottle from #{url}!"
            end
            puts "curl download failed; retrying in #{curl_retry_delay_seconds} sec"
            sleep curl_retry_delay_seconds
            curl_retry_delay_seconds *= 2
            retry_count += 1
          end
        end
        checksum = Checksum.new(:sha256, bottle_info.sha256)
        Pathname.new(filename).verify_checksum(checksum)
      end
    end
  end
end
