#:  * `extract` <formula> <version> <tap>:
#:    Looks through repository history to find the <version> of <formula> and
#:    creates a copy in <tap>/Formula/<formula>@<version>.rb. If the tap is
#:    not installed yet, attempts to install/clone the tap before continuing.
#:
#:    If the file at <tap>/Formula/<formula>@<version>.rb already exists,
#:    it will not be overwritten unless `--force` is specified.
#:

require "utils/git"
require "formula_versions"
require "formulary"
require "tap"

module Homebrew
  module_function

  def extract
    formula = Formulary.factory(ARGV.named[0])
    version = ARGV.named[1]
    dest = Tap.fetch(ARGV.named[2])
    dest.install unless dest.installed?
    path = Pathname.new("#{dest.path}/Formula/#{formula}@#{version}.rb")
    if path.exist?
      unless ARGV.force?
        odie <<~EOS
          Destination formula already exists: #{path}
          To overwrite it and continue anyways, run `brew extract #{formula} #{version} #{dest.name} --force`.
        EOS
      end
      ohai "Clobbering existing formula at #{path}" if ARGV.debug?
      path.delete
    end

    rev = "HEAD"
    version_resolver = FormulaVersions.new(formula)
    rev = Git.last_revision_commit_of_file(formula.path.parent.parent, formula.path, before_commit: "#{rev}~1") until version_resolver.formula_at_revision(rev) { |f| version_matches?(f, version, rev) || rev.empty? }

    odie "Could not find #{formula} #{version}." if rev.empty?

    result = version_resolver.file_contents_at_revision(rev)
    ohai "Writing formula for #{formula} from #{rev} to #{path}"

    # The class name has to be renamed to match the new filename, e.g. Foo version 1.2.3 becomes FooAT123 and resides in Foo@1.2.3.rb.
    path.write result.gsub("class #{formula.name.capitalize} < Formula", "class #{formula.name.capitalize}AT#{version.gsub(/[^0-9a-z ]/i, "")} < Formula")
  end

  # @private
  def version_matches?(formula, version, rev)
    ohai "Trying #{formula.version} from revision #{rev} against desired #{version}" if ARGV.debug?
    formula.version == version
  end
end
