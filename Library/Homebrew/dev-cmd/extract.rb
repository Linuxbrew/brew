#:  * `extract` [`--force`] <formula> `--tap=`<tap> [`--version=`<version>]:
#:    Looks through repository history to find the <version> of <formula> and
#:    creates a copy in <tap>/Formula/<formula>@<version>.rb. If the tap is
#:    not installed yet, attempts to install/clone the tap before continuing.
#:    A tap must be passed through `--tap` in order for `extract` to work.
#:
#:    If `--force` is passed, the file at the destination will be overwritten
#:    if it already exists. Otherwise, existing files will be preserved.
#:
#:    If an argument is passed through `--version`, <version> of <formula>
#:    will be extracted and placed in the destination tap. Otherwise, the most
#:    recent version that can be found will be used.

require "utils/git"
require "formula_versions"
require "formulary"
require "tap"

module Homebrew
  module_function

  def extract
    Homebrew::CLI::Parser.parse do
      flag   "--tap="
      flag   "--version="
      switch :debug
      switch :force
    end

    # If no formula args are given, ask specifically for a formula to be specified
    raise FormulaUnspecifiedError if ARGV.named.empty?

    # If some other number of args are given, provide generic usage information
    raise UsageError if ARGV.named.length != 1

    odie "The tap to which the formula is extracted must be specified!" if args.tap.nil?

    formula = Formulary.factory(ARGV.named.first)
    if args.version.nil?
      version = formula.version
    else
      version = args.version
    end
    destination_tap = Tap.fetch(args.tap)
    destination_tap.install unless destination_tap.installed?

    odie "Cannot extract formula to homebrew/core!" if destination_tap.name == "homebrew/core"

    path = Pathname.new("#{destination_tap.path}/Formula/#{formula}@#{version}.rb")
    if path.exist?
      unless ARGV.force?
        odie <<~EOS
          Destination formula already exists: #{path}
          To overwrite it and continue anyways, run:
            `brew extract #{formula} --version=#{version} --tap=#{destination_tap.name} --force`
        EOS
      end
      ohai "Overwriting existing formula at #{path}" if ARGV.debug?
      path.delete
    end

    if args.version.nil?
      rev = Git.last_revision_commit_of_file(formula.path.parent.parent, formula.path)
      odie "Could not find #{formula} #{version}!" if rev.empty?
      version_resolver = FormulaVersions.new(formula)
    else
      rev = "HEAD"
      version_resolver = FormulaVersions.new(formula)
      until version_resolver.formula_at_revision(rev) { |f| version_matches?(f, version, rev) || rev.empty? } do
        rev = Git.last_revision_commit_of_file(formula.path.parent.parent, formula.path, before_commit: "#{rev}~1")
      end
      odie "Could not find #{formula} #{version}!" if rev.empty?
    end

    result = version_resolver.file_contents_at_revision(rev)

    # The class name has to be renamed to match the new filename, e.g. Foo version 1.2.3 becomes FooAT123 and resides in Foo@1.2.3.rb.
    name = formula.name.capitalize
    versioned_name = Formulary.class_s("#{name}@#{version}")
    result.gsub!("class #{name} < Formula", "class #{versioned_name} < Formula")
    ohai "Writing formula for #{formula} from #{rev} to #{path}"
    path.write result
  end

  # @private
  def version_matches?(formula, version, rev)
    ohai "Trying #{formula.version} from revision #{rev} against desired #{version}" if ARGV.debug?
    formula.version == version
  end
end
