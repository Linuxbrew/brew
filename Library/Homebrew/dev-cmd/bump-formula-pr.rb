# Creates a pull request with the new version of a formula.
#
# Usage: brew bump [options...] <formula-name>
#
# Requires either `--url` and `--sha256` or `--tag` and `--revision`.
#
# Options:
#   --dry-run:  Print what would be done rather than doing it.
#   --devel:    Bump a `devel` rather than `stable` version.
#   --url:      The new formula URL.
#   --sha256:   The new formula SHA-256.
#   --tag:      The new formula's `tag`
#   --revision: The new formula's `revision`.

require "formula"

module Homebrew
  def inreplace_pairs(path, replacement_pairs)
    if ARGV.dry_run?
      contents = path.open("r") { |f| Formulary.set_encoding(f).read }
      contents.extend(StringInreplaceExtension)
      replacement_pairs.each do |old, new|
        ohai "replace \"#{old}\" with \"#{new}\"" unless ARGV.flag?("--quiet")
        contents.gsub!(old, new)
      end
      if contents.errors.any?
        raise Utils::InreplaceError, path => contents.errors
      end
      contents
    else
      Utils::Inreplace.inreplace(path) do |s|
        replacement_pairs.each do |old, new|
          ohai "replace \"#{old}\" with \"#{new}\"" unless ARGV.flag?("--quiet")
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

    replacement_pairs = if new_url_hash
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
        ohai "git checkout -b #{branch} origin/master"
        ohai "git commit --no-edit --verbose --message='#{formula.name} #{new_formula_version}#{devel_message}' -- #{formula.path}"
        ohai "hub fork --no-remote"
        ohai "hub fork"
        ohai "hub fork (to read $HUB_REMOTE)"
        ohai "git push $HUB_REMOTE #{branch}:#{branch}"
        ohai "hub pull-request --browse -m '#{formula.name} #{new_formula_version}#{devel_message}'"
      else
        safe_system "git", "checkout", "-b", branch, "origin/master"
        safe_system "git", "commit", "--no-edit", "--verbose",
          "--message=#{formula.name} #{new_formula_version}#{devel_message}",
          "--", formula.path
        safe_system "hub", "fork", "--no-remote"
        quiet_system "hub", "fork"
        remote = Utils.popen_read("hub fork 2>&1")[/fatal: remote (.+) already exists./, 1]
        odie "cannot get remote from 'hub'!" if remote.to_s.empty?
        safe_system "git", "push", remote, "#{branch}:#{branch}"
        safe_system "hub", "pull-request", "--browse", "-m",
          "#{formula.name} #{new_formula_version}#{devel_message}\n\nCreated with `brew bump-formula-pr`."
      end
    end
  end
end
