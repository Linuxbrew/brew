#:  * `create` [`--autotools`|`--cmake`|`--meson`] [`--no-fetch`] [`--set-name` <name>] [`--set-version` <version>] [`--tap` <user>`/`<repo>] <URL>:
#:    Generate a formula for the downloadable file at <URL> and open it in the editor.
#:    Homebrew will attempt to automatically derive the formula name
#:    and version, but if it fails, you'll have to make your own template. The `wget`
#:    formula serves as a simple example. For the complete API, see:
#:    <https://www.rubydoc.info/github/Homebrew/brew/master/Formula>
#:
#:    If `--autotools` is passed, create a basic template for an Autotools-style build.
#:    If `--cmake` is passed, create a basic template for a CMake-style build.
#:    If `--meson` is passed, create a basic template for a Meson-style build.
#:
#:    If `--no-fetch` is passed, Homebrew will not download <URL> to the cache and
#:    will thus not add the SHA-256 to the formula for you, nor will it check
#:    the GitHub API for GitHub projects (to fill out its description and homepage).
#:
#:    The options `--set-name` and `--set-version` each take an argument and allow
#:    you to explicitly set the name and version of the package you are creating.
#:
#:    The option `--tap` takes a tap as its argument and generates the formula in
#:    the specified tap.

require "formula"
require "formula_creator"
require "missing_formula"
require "cli_parser"

module Homebrew
  module_function

  def create_args
    Homebrew::CLI::Parser.new do
      usage_banner <<~EOS
        `create` [<options>] <URL>

        Generate a formula for the downloadable file at <URL> and open it in the editor.
        Homebrew will attempt to automatically derive the formula name and version, but
        if it fails, you'll have to make your own template. The `wget` formula serves as
        a simple example. For the complete API, see:
        <http://www.rubydoc.info/github/Homebrew/brew/master/Formula>
      EOS
      switch "--autotools",
        description: "Create a basic template for an Autotools-style build."
      switch "--cmake",
        description: "Create a basic template for a CMake-style build."
      switch "--meson",
        description: "Create a basic template for a Meson-style build."
      switch "--no-fetch",
        description: "Homebrew will not download <URL> to the cache and will thus not add the SHA-256 "\
                     "to the formula for you, nor will it check the GitHub API for GitHub projects "\
                     "(to fill out its description and homepage)."
      switch "--HEAD",
        description: "Indicate that <URL> points to the package's repository rather than a file."
      flag   "--set-name=",
        description: "Set the name of the new formula to the provided <name>."
      flag   "--set-version=",
        description: "Set the version of the new formula to the provided <version>."
      flag   "--tap=",
        description: "Generate the new formula in the provided tap, specified as <user>`/`<repo>."
      switch :force
      switch :verbose
      switch :debug
    end
  end

  # Create a formula from a tarball URL
  def create
    create_args.parse

    raise UsageError if ARGV.named.empty?

    # Ensure that the cache exists so we can fetch the tarball
    HOMEBREW_CACHE.mkpath

    url = ARGV.named.first # Pull the first (and only) url from ARGV

    version = args.set_version
    name = args.set_name
    tap = args.tap

    fc = FormulaCreator.new
    fc.name = name
    fc.version = version
    fc.tap = Tap.fetch(tap || "homebrew/core")
    raise TapUnavailableError, tap unless fc.tap.installed?

    fc.url = url

    fc.mode = if args.cmake?
      :cmake
    elsif args.autotools?
      :autotools
    elsif args.meson?
      :meson
    end

    if fc.name.nil? || fc.name.strip.empty?
      stem = Pathname.new(url).stem
      print "Formula name [#{stem}]: "
      fc.name = __gets || stem
      fc.update_path
    end

    # Don't allow blacklisted formula, or names that shadow aliases,
    # unless --force is specified.
    unless args.force?
      if reason = MissingFormula.blacklisted_reason(fc.name)
        raise <<~EOS
          #{fc.name} is blacklisted for creation.
          #{reason}
          If you really want to create this formula use --force.
        EOS
      end

      if Formula.aliases.include? fc.name
        realname = Formulary.canonical_name(fc.name)
        raise <<~EOS
          The formula #{realname} is already aliased to #{fc.name}
          Please check that you are not creating a duplicate.
          To force creation use --force.
        EOS
      end
    end

    fc.generate!

    puts "Please `brew audit --new-formula #{fc.name}` before submitting, thanks."
    exec_editor fc.path
  end

  def __gets
    gots = $stdin.gets.chomp
    gots.empty? ? nil : gots
  end
end
