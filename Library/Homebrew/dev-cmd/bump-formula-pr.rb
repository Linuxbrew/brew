#:  * `bump-formula-pr` [`--devel`] [`--dry-run`] [`--audit`|`--strict`] `--url=`<url> `--sha256=`<sha-256> <formula>:
#:  * `bump-formula-pr` [`--devel`] [`--dry-run`] [`--audit`|`--strict`] `--tag=`<tag> `--revision=`<revision> <formula>:
#:    Creates a pull request to update the formula with a new url or a new tag.
#:
#:    If a <url> is specified, the <sha-256> checksum of the new download must
#:    also be specified. A best effort to determine the <sha-256> and <formula>
#:    name will be made if either or both values are not supplied by the user.
#:
#:    If a <tag> is specified, the git commit <revision> corresponding to that
#:    tag must also be specified.
#:
#:    If `--devel` is passed, bump the development rather than stable version.
#:    The development spec must already exist.
#:
#:    If `--dry-run` is passed, print what would be done rather than doing it.
#:
#:    If `--write` is passed along with `--dry-run`, perform a not-so-dry run
#:    making the expected file modifications but not taking any git actions.
#:
#:    If `--audit` is passed, run `brew audit` before opening the PR.
#:
#:    If `--strict` is passed, run `brew audit --strict` before opening the PR.
#:
#:    If `--mirror=`<url> is passed, use the value as a mirror url.
#:
#:    If `--version=`<version> is passed, use the value to override the value
#:    parsed from the url or tag. Note that `--version=0` can be used to delete
#:    an existing `version` override from a formula if it has become redundant.
#:
#:    Note that this command cannot be used to transition a formula from a
#:    url-and-sha256 style specification into a tag-and-revision style
#:    specification, nor vice versa. It must use whichever style specification
#:    the preexisting formula already uses.

require "formula"

module Homebrew
  module_function

  def inreplace_pairs(path, replacement_pairs)
    if ARGV.dry_run?
      contents = path.open("r") { |f| Formulary.ensure_utf8_encoding(f).read }
      contents.extend(StringInreplaceExtension)
      replacement_pairs.each do |old, new|
        unless ARGV.flag?("--quiet")
          ohai "replace #{old.inspect} with #{new.inspect}"
        end
        contents.gsub!(old, new)
      end
      unless contents.errors.empty?
        raise Utils::InreplaceError, path => contents.errors
      end
      path.atomic_write(contents) if ARGV.include?("--write")
      contents
    else
      Utils::Inreplace.inreplace(path) do |s|
        replacement_pairs.each do |old, new|
          unless ARGV.flag?("--quiet")
            ohai "replace #{old.inspect} with #{new.inspect}"
          end
          s.gsub!(old, new)
        end
      end
      path.open("r") { |f| Formulary.ensure_utf8_encoding(f).read }
    end
  end

  def formula_version(formula, spec, contents = nil)
    name = formula.name
    path = formula.path
    if contents
      Formulary.from_contents(name, path, contents, spec).version
    else
      Formulary::FormulaLoader.new(name, path).get_formula(spec).version
    end
  end

  def bump_formula_pr
    formula = ARGV.formulae.first
    new_url = ARGV.value("url")
    if new_url && !formula
      is_devel = ARGV.include?("--devel")
      base_url = new_url.split("/")[0..4].join("/")
      base_url = /#{Regexp.escape(base_url)}/
      guesses = []
      Formula.each do |f|
        if is_devel && f.devel && f.devel.url && f.devel.url.match(base_url)
          guesses << f
        elsif f.stable && f.stable.url && f.stable.url.match(base_url)
          guesses << f
        end
      end
      if guesses.count == 1
        formula = guesses.shift
      elsif guesses.count > 1
        odie "Couldn't guess formula for sure: could be one of these:\n#{guesses}"
      end
    end
    odie "No formula found!" unless formula

    requested_spec, formula_spec = if ARGV.include?("--devel")
      devel_message = " (devel)"
      [:devel, formula.devel]
    else
      [:stable, formula.stable]
    end
    odie "#{formula}: no #{requested_spec} specification found!" unless formula_spec

    hash_type, old_hash = if (checksum = formula_spec.checksum)
      [checksum.hash_type.to_s, checksum.hexdigest]
    end

    new_hash = ARGV.value(hash_type)
    new_tag = ARGV.value("tag")
    new_revision = ARGV.value("revision")
    new_mirror = ARGV.value("mirror")
    forced_version = ARGV.value("version")
    new_url_hash = if new_url && new_hash
      true
    elsif new_tag && new_revision
      false
    elsif !hash_type
      odie "#{formula}: no tag/revision specified!"
    else
      rsrc_url = if requested_spec != :devel && new_url =~ /.*ftpmirror.gnu.*/
        new_mirror = new_url.sub "ftpmirror.gnu.org", "ftp.gnu.org/gnu"
        new_mirror
      else
        new_url
      end
      rsrc = Resource.new { @url = rsrc_url }
      rsrc.download_strategy = CurlDownloadStrategy
      rsrc.owner = Resource.new(formula.name)
      rsrc_path = rsrc.fetch
      if Utils.popen_read("/usr/bin/tar", "-tf", rsrc_path) =~ %r{/.*\.}
        new_hash = rsrc_path.sha256
      elsif new_url.include? ".tar"
        odie "#{formula}: no url/#{hash_type} specified!"
      end
    end

    if ARGV.dry_run?
      ohai "brew update"
    else
      safe_system "brew", "update"
    end

    old_formula_version = formula_version(formula, requested_spec)

    replacement_pairs = []
    if requested_spec == :stable && formula.revision.nonzero?
      replacement_pairs << [/^  revision \d+\n(\n(  head "))?/m, "\\2"]
    end

    replacement_pairs << [/(^  mirror .*\n)?/, ""] if requested_spec == :stable

    replacement_pairs += if new_url_hash
      [
        [formula_spec.url, new_url],
        [old_hash, new_hash],
      ]
    else
      [
        [formula_spec.specs[:tag], new_tag],
        [formula_spec.specs[:revision], new_revision],
      ]
    end

    backup_file = File.read(formula.path) unless ARGV.dry_run?

    if new_mirror
      replacement_pairs << [/^( +)(url \"#{new_url}\"\n)/m, "\\1\\2\\1mirror \"#{new_mirror}\"\n"]
    end

    if forced_version && forced_version != "0"
      if requested_spec == :stable
        if File.read(formula.path).include?("version \"#{old_formula_version}\"")
          replacement_pairs << [old_formula_version.to_s, forced_version]
        elsif new_mirror
          replacement_pairs << [/^( +)(mirror \"#{new_mirror}\"\n)/m, "\\1\\2\\1version \"#{forced_version}\"\n"]
        else
          replacement_pairs << [/^( +)(url \"#{new_url}\"\n)/m, "\\1\\2\\1version \"#{forced_version}\"\n"]
        end
      elsif requested_spec == :devel
        replacement_pairs << [/(  devel do.+?version \")#{old_formula_version}(\"\n.+?end\n)/m, "\\1#{forced_version}\\2"]
      end
    elsif forced_version && forced_version == "0"
      if requested_spec == :stable
        replacement_pairs << [/^  version \"[a-z\d+\.]+\"\n/m, ""]
      elsif requested_spec == :devel
        replacement_pairs << [/(  devel do.+?)^ +version \"[^\n]+\"\n(.+?end\n)/m, "\\1\\2"]
      end
    end
    new_contents = inreplace_pairs(formula.path, replacement_pairs)

    new_formula_version = formula_version(formula, requested_spec, new_contents)

    if new_formula_version < old_formula_version
      formula.path.atomic_write(backup_file) unless ARGV.dry_run?
      odie <<-EOS.undent
        You probably need to bump this formula manually since changing the
        version from #{old_formula_version} to #{new_formula_version} would be a downgrade.
      EOS
    elsif new_formula_version == old_formula_version
      formula.path.atomic_write(backup_file) unless ARGV.dry_run?
      odie <<-EOS.undent
        You probably need to bump this formula manually since the new version
        and old version are both #{new_formula_version}.
      EOS
    end

    if ARGV.dry_run?
      if ARGV.include? "--strict"
        ohai "brew audit --strict #{formula.path.basename}"
      elsif ARGV.include? "--audit"
        ohai "brew audit #{formula.path.basename}"
      end
    else
      failed_audit = false
      if ARGV.include? "--strict"
        system HOMEBREW_BREW_FILE, "audit", "--strict", formula.path
        failed_audit = !$?.success?
      elsif ARGV.include? "--audit"
        system HOMEBREW_BREW_FILE, "audit", formula.path
        failed_audit = !$?.success?
      end
      if failed_audit
        formula.path.atomic_write(backup_file)
        odie "brew audit failed!"
      end
    end

    unless Formula["hub"].any_version_installed?
      if ARGV.dry_run?
        ohai "brew install hub"
      else
        safe_system "brew", "install", "hub"
      end
    end

    formula.path.parent.cd do
      branch = "#{formula.name}-#{new_formula_version}"
      if ARGV.dry_run?
        ohai "git checkout --no-track -b #{branch} origin/master"
        ohai "git commit --no-edit --verbose --message='#{formula.name} #{new_formula_version}#{devel_message}' -- #{formula.path}"
        ohai "hub fork --no-remote"
        ohai "hub fork"
        ohai "hub fork (to read $HUB_REMOTE)"
        ohai "git push --set-upstream $HUB_REMOTE #{branch}:#{branch}"
        ohai "hub pull-request --browse -m '#{formula.name} #{new_formula_version}#{devel_message}'"
        ohai "git checkout -"
      else
        safe_system "git", "checkout", "--no-track", "-b", branch, "origin/master"
        safe_system "git", "commit", "--no-edit", "--verbose",
          "--message=#{formula.name} #{new_formula_version}#{devel_message}",
          "--", formula.path
        safe_system "hub", "fork", "--no-remote"
        quiet_system "hub", "fork"
        remote = Utils.popen_read("hub fork 2>&1")[/fatal: remote (.+) already exists\./, 1]
        odie "cannot get remote from 'hub'!" if remote.to_s.empty?
        safe_system "git", "push", "--set-upstream", remote, "#{branch}:#{branch}"
        safe_system "hub", "pull-request", "--browse", "-m",
          "#{formula.name} #{new_formula_version}#{devel_message}\n\nCreated with `brew bump-formula-pr`."
        safe_system "git", "checkout", "-"
      end
    end
  end
end
