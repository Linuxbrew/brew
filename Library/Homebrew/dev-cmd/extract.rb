#:  * `extract` [`--force`] [`--stdout`] <formula> <version> [<tap>]:
#:    Looks through repository history to find the <version> of <formula> and
#:    creates a copy in <tap>/Formula/<formula>@<version>.rb. If the tap is
#:    not installed yet, attempts to install/clone the tap before continuing.
#:
#:    If `--force` is passed, the file at the destination will be overwritten
#:    if it already exists. Otherwise, existing files will be preserved.
#:
#:    If `--stdout` is passed, the file will be written to stdout on the
#:    terminal instead of written to a file. A <tap> cannot be passed when
#:    using `--stdout`.

require "utils/git"
require "formula_versions"
require "formulary"
require "tap"

module Homebrew
  module_function

  def extract
  	Homebrew::CLI::Parser.parse do
      switch      "--stdout", description: "Output to stdout on terminal instead of file"
      switch      :debug
      switch      :force
	  end

    odie "Cannot use a tap and --stdout at the same time!" if ARGV.named.length == 3 && args.stdout?
    raise UsageError unless (ARGV.named.length == 3 && !args.stdout?) || (ARGV.named.length == 2 && args.stdout?)

    formula = Formulary.factory(ARGV.named.first)
    version = ARGV.named[1]
    destination_tap = Tap.fetch(ARGV.named[2]) unless args.stdout?
    destination_tap.install unless destination_tap.installed? unless args.stdout?

    unless args.stdout?
      path = Pathname.new("#{destination_tap.path}/Formula/#{formula}@#{version}.rb")
      if path.exist?
        unless ARGV.force?
          odie <<~EOS
            Destination formula already exists: #{path}
            To overwrite it and continue anyways, run `brew extract #{formula} #{version} #{destination_tap.name} --force`.
          EOS
        end
        ohai "Overwriting existing formula at #{path}" if ARGV.debug?
        path.delete
      end
    end

    rev = "HEAD"
    version_resolver = FormulaVersions.new(formula)
    until version_resolver.formula_at_revision(rev) { |f| version_matches?(f, version, rev) || rev.empty? } do
      rev = Git.last_revision_commit_of_file(formula.path.parent.parent, formula.path, before_commit: "#{rev}~1")
    end

    odie "Could not find #{formula} #{version}!" if rev.empty?

    result = version_resolver.file_contents_at_revision(rev)

    # The class name has to be renamed to match the new filename, e.g. Foo version 1.2.3 becomes FooAT123 and resides in Foo@1.2.3.rb.
    result.gsub!("class #{formula.name.capitalize} < Formula", "class #{formula.name.capitalize}AT#{version.gsub(/[^0-9a-z ]/i, "")} < Formula")
    if args.stdout?
      puts result if args.stdout?
    else
      ohai "Writing formula for #{formula} from #{rev} to #{path}"
      path.write result
    end
  end

  # @private
  def version_matches?(formula, version, rev)
    ohai "Trying #{formula.version} from revision #{rev} against desired #{version}" if ARGV.debug?
    formula.version == version
  end
end
