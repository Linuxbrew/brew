#:  * `bump-formula-pr` [`--devel`] [`--dry-run`] `--url=`<url> `--sha256=`<sha-256> <formula>:
#:  * `bump-formula-pr` [`--devel`] [`--dry-run`] `--tag=`<tag> `--revision=`<revision> <formula>:
#:    Creates a pull request to update the formula with a new url or a new tag.
#:
#:    If a <url> is specified, the <sha-256> checksum of the new download must
#:    also be specified.
#:
#:    If a <tag> is specified, the git commit <revision> corresponding to that
#:    tag must also be specified.
#:
#:    If `--devel` is passed, bump the development rather than stable version.
#:    The development spec must already exist.
#:
#:    If `--dry-run` is passed, print what would be done rather than doing it.
#:
#:    Note that this command cannot be used to transition a formula from a
#:    url-and-sha256 style specification into a tag-and-revision style
#:    specification, nor vice versa. It must use whichever style specification
#:    the preexisting formula already uses.

require "formula"

module Homebrew
  def inreplace_pairs(path, replacement_pairs)
    if ARGV.dry_run?
      contents = path.open("r") { |f| Formulary.set_encoding(f).read }
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
      path.open("r") { |f| Formulary.set_encoding(f).read }
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

    new_url = ARGV.value("url")
    new_hash = ARGV.value(hash_type)
    new_tag = ARGV.value("tag")
    new_revision = ARGV.value("revision")
    new_url_hash = if new_url && new_hash
      true
    elsif new_tag && new_revision
      false
    elsif !hash_type
      odie "#{formula}: no tag/revision specified!"
    else
      odie "#{formula}: no url/#{hash_type} specified!"
    end

    if ARGV.dry_run?
      ohai "brew update"
    else
      safe_system "brew", "update"
    end

    old_formula_version = formula_version(formula, requested_spec)

    replacement_pairs = []
    if requested_spec == :stable && formula.revision != 0
      replacement_pairs << [/^  revision \d+\n(\n(  head "))?/m, "\\2"]
    end

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

    new_contents = inreplace_pairs(formula.path, replacement_pairs)

    new_formula_version = formula_version(formula, requested_spec, new_contents)

    if new_formula_version < old_formula_version
      odie <<-EOS.undent
        You probably need to bump this formula manually since changing the
        version from #{old_formula_version} to #{new_formula_version} would be a downgrade.
      EOS
    elsif new_formula_version == old_formula_version
      odie <<-EOS.undent
        You probably need to bump this formula manually since the new version
        and old version are both #{new_formula_version}.
      EOS
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
