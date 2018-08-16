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
require "formulary"
require "tap"

class BottleSpecification
  def method_missing(m, *_args, &_block)
    # no-op
  end
end

class Module
  def method_missing(m, *_args, &_block)
    # no-op
  end
end

class DependencyCollector
  def parse_symbol_spec(spec, tags)
    case spec
    when :x11        then X11Requirement.new(spec.to_s, tags)
    when :xcode      then XcodeRequirement.new(tags)
    when :linux      then LinuxRequirement.new(tags)
    when :macos      then MacOSRequirement.new(tags)
    when :arch       then ArchRequirement.new(tags)
    when :java       then JavaRequirement.new(tags)
    when :osxfuse    then OsxfuseRequirement.new(tags)
    when :tuntap     then TuntapRequirement.new(tags)
    when :ld64       then ld64_dep_if_needed(tags)
    else
      # no-op
    end
  end

  module Compat
    def parse_string_spec(spec, tags)
      opoo "'depends_on ... => :run' is disabled. There is no replacement." if tags.include?(:run) && ARGV.debug?
      super
    end
  end

  prepend Compat
end

module Homebrew
  module_function

  def extract
    Homebrew::CLI::Parser.parse do
      flag   "--version="
      switch :debug
      switch :force
    end

    # Expect exactly two named arguments: formula and tap
    raise UsageError if ARGV.named.length != 2

    destination_tap = Tap.fetch(ARGV.named[1])
    odie "Cannot extract formula to homebrew/core!" if destination_tap.core_tap?
    destination_tap.install unless destination_tap.installed?

    core = CoreTap.instance
    name = ARGV.named.first.downcase
    repo = core.path
    file = core.path/"Formula/#{name}.rb"

    if args.version
      version = args.version
      rev = "HEAD"
      test_formula = nil
      loop do
        loop do
          rev = Git.last_revision_commit_of_file(repo, file, before_commit: "#{rev}~1")
          break if rev.empty?
          break unless Git.last_revision_of_file(repo, file, before_commit: rev).empty?
          ohai "Skipping revision #{rev} - file is empty at this revision" if ARGV.debug?
        end
        test_formula = formula_at_revision(repo, name, file, rev)
        break if test_formula.nil? || test_formula.version == version
        ohai "Trying #{test_formula.version} from revision #{rev} against desired #{version}" if ARGV.debug?
      end
      odie "Could not find #{name}! The formula or version may not have existed." if test_formula.nil?
      result = Git.last_revision_of_file(repo, file, before_commit: rev)
    else
      rev = Git.last_revision_commit_of_file(repo, file)
      version = formula_at_revision(repo, name, file, rev).version
      odie "Could not find #{name}! The formula or version may not have existed." if rev.empty?
      result = Git.last_revision_of_file(repo, file)
    end

    # The class name has to be renamed to match the new filename, e.g. Foo version 1.2.3 becomes FooAT123 and resides in Foo@1.2.3.rb.
    class_name = name.capitalize
    versioned_name = Formulary.class_s("#{class_name}@#{version}")
    result.gsub!("class #{class_name} < Formula", "class #{versioned_name} < Formula")

    path = destination_tap.path/"Formula/#{name}@#{version}.rb"
    if path.exist?
      unless ARGV.force?
        odie <<~EOS
          Destination formula already exists: #{path}
          To overwrite it and continue anyways, run:
            `brew extract #{name} --version=#{version} --tap=#{destination_tap.name} --force`
        EOS
      end
      ohai "Overwriting existing formula at #{path}" if ARGV.debug?
      path.delete
    end
    ohai "Writing formula for #{name} from #{rev} to #{path}"
    path.write result
  end

  # @private
  def formula_at_revision(repo, name, file, rev)
    return if rev.empty?
    contents = Git.last_revision_of_file(repo, file, before_commit: rev)
    contents.gsub!("@url=", "url ")
    contents.gsub!("require 'brewkit'", "require 'formula'")
    Formulary.from_contents(name, file, contents)
  end
end
