require "cache_store"
require "formula_support"
require "lock_file"
require "formula_pin"
require "hardware"
require "utils/bottles"
require "utils/shell"
require "build_environment"
require "build_options"
require "formulary"
require "software_spec"
require "install_renamed"
require "pkg_version"
require "keg"
require "migrator"
require "linkage_checker"
require "extend/ENV"
require "language/python"
require "tab"
require "mktemp"

# A formula provides instructions and metadata for Homebrew to install a piece
# of software. Every Homebrew formula is a {Formula}.
# All subclasses of {Formula} (and all Ruby classes) have to be named
# `UpperCase` and `not-use-dashes`.
# A formula specified in `this-formula.rb` should have a class named
# `ThisFormula`. Homebrew does enforce that the name of the file and the class
# correspond.
# Make sure you check with `brew search` that the name is free!
# @abstract
# @see SharedEnvExtension
# @see Pathname
# @see https://www.rubydoc.info/stdlib/fileutils FileUtils
# @see https://docs.brew.sh/Formula-Cookbook Formula Cookbook
# @see https://github.com/styleguide/ruby Ruby Style Guide
#
# <pre>class Wget < Formula
#   homepage "https://www.gnu.org/software/wget/"
#   url "https://ftp.gnu.org/gnu/wget/wget-1.15.tar.gz"
#   sha256 "52126be8cf1bddd7536886e74c053ad7d0ed2aa89b4b630f76785bac21695fcd"
#
#   def install
#     system "./configure", "--prefix=#{prefix}"
#     system "make", "install"
#   end
# end</pre>
class Formula
  include FileUtils
  include Utils::Inreplace
  include Utils::Shell
  extend Enumerable
  extend Forwardable

  # @!method inreplace(paths, before = nil, after = nil)
  # Actually implemented in {Utils::Inreplace.inreplace}.
  # Sometimes we have to change a bit before we install. Mostly we
  # prefer a patch but if you need the `prefix` of this formula in the
  # patch you have to resort to `inreplace`, because in the patch
  # you don't have access to any var defined by the formula. Only
  # `HOMEBREW_PREFIX` is available in the embedded patch.
  #
  # `inreplace` supports regular expressions:
  # <pre>inreplace "somefile.cfg", /look[for]what?/, "replace by #{bin}/tool"</pre>
  # @see Utils::Inreplace.inreplace

  # The name of this {Formula}.
  # e.g. `this-formula`
  attr_reader :name

  # The path to the alias that was used to identify this {Formula}.
  # e.g. `/usr/local/Library/Taps/homebrew/homebrew-core/Aliases/another-name-for-this-formula`
  attr_reader :alias_path

  # The name of the alias that was used to identify this {Formula}.
  # e.g. `another-name-for-this-formula`
  attr_reader :alias_name

  # The fully-qualified name of this {Formula}.
  # For core formula it's the same as {#name}.
  # e.g. `homebrew/tap-name/this-formula`
  attr_reader :full_name

  # The fully-qualified alias referring to this {Formula}.
  # For core formula it's the same as {#alias_name}.
  # e.g. `homebrew/tap-name/another-name-for-this-formula`
  attr_reader :full_alias_name

  # The full path to this {Formula}.
  # e.g. `/usr/local/Library/Taps/homebrew/homebrew-core/Formula/this-formula.rb`
  attr_reader :path

  # The {Tap} instance associated with this {Formula}.
  # If it's <code>nil</code>, then this formula is loaded from path or URL.
  # @private
  attr_reader :tap

  # The stable (and default) {SoftwareSpec} for this {Formula}
  # This contains all the attributes (e.g. URL, checksum) that apply to the
  # stable version of this formula.
  # @private
  attr_reader :stable

  # The development {SoftwareSpec} for this {Formula}.
  # Installed when using `brew install --devel`
  # `nil` if there is no development version.
  # @see #stable
  # @private
  attr_reader :devel

  # The HEAD {SoftwareSpec} for this {Formula}.
  # Installed when using `brew install --HEAD`
  # This is always installed with the version `HEAD` and taken from the latest
  # commit in the version control system.
  # `nil` if there is no HEAD version.
  # @see #stable
  # @private
  attr_reader :head

  # The currently active {SoftwareSpec}.
  # @see #determine_active_spec
  attr_reader :active_spec
  protected :active_spec

  # A symbol to indicate currently active {SoftwareSpec}.
  # It's either :stable, :devel or :head
  # @see #active_spec
  # @private
  attr_reader :active_spec_sym

  # most recent modified time for source files
  # @private
  attr_reader :source_modified_time

  # Used for creating new Homebrew versions of software without new upstream
  # versions.
  # @see .revision=
  attr_reader :revision

  # Used to change version schemes for packages
  attr_reader :version_scheme

  # The current working directory during builds.
  # Will only be non-`nil` inside {#install}.
  attr_reader :buildpath

  # The current working directory during tests.
  # Will only be non-`nil` inside {.test}.
  attr_reader :testpath

  # When installing a bottle (binary package) from a local path this will be
  # set to the full path to the bottle tarball. If not, it will be `nil`.
  # @private
  attr_accessor :local_bottle_path

  # When performing a build, test, or other loggable action, indicates which
  # log file location to use.
  # @private
  attr_reader :active_log_type

  # The {BuildOptions} for this {Formula}. Lists the arguments passed and any
  # {.option}s in the {Formula}. Note that these may differ at different times
  # during the installation of a {Formula}. This is annoying but the result of
  # state that we're trying to eliminate.
  # @return [BuildOptions]
  attr_accessor :build

  # A Boolean indicating whether this formula should be considered outdated
  # if the target of the alias it was installed with has since changed.
  # Defaults to true.
  # @return [Boolean]
  attr_accessor :follow_installed_alias
  alias follow_installed_alias? follow_installed_alias

  # @private
  def initialize(name, path, spec, alias_path: nil)
    @name = name
    @path = path
    @alias_path = alias_path
    @alias_name = if alias_path
      File.basename(alias_path)
    end
    @revision = self.class.revision || 0
    @version_scheme = self.class.version_scheme || 0

    @tap = if path == Formulary.core_path(name)
      CoreTap.instance
    else
      Tap.from_path(path)
    end

    @full_name = full_name_with_optional_tap(name)
    @full_alias_name = full_name_with_optional_tap(@alias_name)

    spec_eval :stable
    spec_eval :devel
    spec_eval :head

    @active_spec = determine_active_spec(spec)
    @active_spec_sym = if head?
      :head
    elsif devel?
      :devel
    else
      :stable
    end
    validate_attributes!
    @build = active_spec.build
    @pin = FormulaPin.new(self)
    @follow_installed_alias = true
    @prefix_returns_versioned_prefix = false
    @oldname_lock = nil
  end

  # @private
  def active_spec=(spec_sym)
    spec = send(spec_sym)
    raise FormulaSpecificationError, "#{spec_sym} spec is not available for #{full_name}" unless spec

    @active_spec = spec
    @active_spec_sym = spec_sym
    validate_attributes!
    @build = active_spec.build
  end

  private

  # Allow full name logic to be re-used between names, aliases,
  # and installed aliases.
  def full_name_with_optional_tap(name)
    if name.nil? || @tap.nil? || @tap.core_tap?
      name
    else
      "#{@tap}/#{name}"
    end
  end

  def spec_eval(name)
    spec = self.class.send(name)
    return unless spec.url

    spec.owner = self
    instance_variable_set("@#{name}", spec)
  end

  def determine_active_spec(requested)
    spec = send(requested) || stable || devel || head
    spec || raise(FormulaSpecificationError, "formulae require at least a URL")
  end

  def validate_attributes!
    if name.nil? || name.empty? || name =~ /\s/
      raise FormulaValidationError.new(full_name, :name, name)
    end

    url = active_spec.url
    if url.nil? || url.empty? || url =~ /\s/
      raise FormulaValidationError.new(full_name, :url, url)
    end

    val = version.respond_to?(:to_str) ? version.to_str : version
    return unless val.nil? || val.empty? || val =~ /\s/

    raise FormulaValidationError.new(full_name, :version, val)
  end

  public

  # The alias path that was used to install this formula, if it exists.
  # Can differ from {#alias_path}, which is the alias used to find the formula,
  # and is specified to this instance.
  def installed_alias_path
    path = build.source["path"] if build.is_a?(Tab)
    return unless path =~ %r{#{HOMEBREW_TAP_DIR_REGEX}/Aliases}
    return unless File.symlink?(path)

    path
  end

  def installed_alias_name
    File.basename(installed_alias_path) if installed_alias_path
  end

  def full_installed_alias_name
    full_name_with_optional_tap(installed_alias_name)
  end

  # The path that was specified to find this formula.
  def specified_path
    alias_path || path
  end

  # The name specified to find this formula.
  def specified_name
    alias_name || name
  end

  # The name (including tap) specified to find this formula.
  def full_specified_name
    full_alias_name || full_name
  end

  # The name specified to install this formula.
  def installed_specified_name
    installed_alias_name || name
  end

  # The name (including tap) specified to install this formula.
  def full_installed_specified_name
    full_installed_alias_name || full_name
  end

  # Is the currently active {SoftwareSpec} a {#stable} build?
  # @private
  def stable?
    active_spec == stable
  end

  # Is the currently active {SoftwareSpec} a {#devel} build?
  # @private
  def devel?
    active_spec == devel
  end

  # Is the currently active {SoftwareSpec} a {#head} build?
  # @private
  def head?
    active_spec == head
  end

  delegate [ # rubocop:disable Layout/AlignHash
    :bottle_unneeded?,
    :bottle_disabled?,
    :bottle_disable_reason,
    :bottle_defined?,
    :bottled?,
    :bottle_specification,
    :downloader,
  ] => :active_spec

  # The Bottle object for the currently active {SoftwareSpec}.
  # @private
  def bottle
    Bottle.new(self, bottle_specification) if bottled?
  end

  # The description of the software.
  # @method desc
  # @see .desc=
  delegate desc: :"self.class"

  # The homepage for the software.
  # @method homepage
  # @see .homepage=
  delegate homepage: :"self.class"

  # The version for the currently active {SoftwareSpec}.
  # The version is autodetected from the URL and/or tag so only needs to be
  # declared if it cannot be autodetected correctly.
  # @method version
  # @see .version
  delegate version: :active_spec

  def update_head_version
    return unless head?
    return unless head.downloader.is_a?(VCSDownloadStrategy)
    return unless head.downloader.cached_location.exist?

    path = if ENV["HOMEBREW_ENV"]
      ENV["PATH"]
    else
      ENV["HOMEBREW_PATH"]
    end

    with_env(PATH: path) do
      head.version.update_commit(head.downloader.last_commit)
    end
  end

  # The {PkgVersion} for this formula with {version} and {#revision} information.
  def pkg_version
    PkgVersion.new(version, revision)
  end

  # If this is a `@`-versioned formula.
  def versioned_formula?
    name.include?("@")
  end

  # Returns any `@`-versioned formulae for an non-`@`-versioned formula.
  def versioned_formulae
    return [] if versioned_formula?

    Pathname.glob(path.to_s.gsub(/\.rb$/, "@*.rb")).map do |path|
      begin
        Formula[path.basename(".rb").to_s]
      rescue FormulaUnavailableError
        nil
      end
    end.compact.sort
  end

  # A named Resource for the currently active {SoftwareSpec}.
  # Additional downloads can be defined as {#resource}s.
  # {Resource#stage} will create a temporary directory and yield to a block.
  # <pre>resource("additional_files").stage { bin.install "my/extra/tool" }</pre>
  # @method resource
  delegate resource: :active_spec

  # An old name for the formula
  def oldname
    @oldname ||= if tap
      formula_renames = tap.formula_renames
      formula_renames.to_a.rassoc(name).first if formula_renames.value?(name)
    end
  end

  # All aliases for the formula
  def aliases
    @aliases ||= if tap
      tap.alias_reverse_table[full_name].to_a.map do |a|
        a.split("/").last
      end
    else
      []
    end
  end

  # The {Resource}s for the currently active {SoftwareSpec}.
  # @method resources
  def_delegator :"active_spec.resources", :values, :resources

  # The {Dependency}s for the currently active {SoftwareSpec}.
  delegate deps: :active_spec

  # The {Requirement}s for the currently active {SoftwareSpec}.
  delegate requirements: :active_spec

  # The cached download for the currently active {SoftwareSpec}.
  delegate cached_download: :active_spec

  # Deletes the download for the currently active {SoftwareSpec}.
  delegate clear_cache: :active_spec

  # The list of patches for the currently active {SoftwareSpec}.
  def_delegator :active_spec, :patches, :patchlist

  # The options for the currently active {SoftwareSpec}.
  delegate options: :active_spec

  # The deprecated options for the currently active {SoftwareSpec}.
  delegate deprecated_options: :active_spec

  # The deprecated option flags for the currently active {SoftwareSpec}.
  delegate deprecated_flags: :active_spec

  # If a named option is defined for the currently active {SoftwareSpec}.
  # @method option_defined?
  delegate option_defined?: :active_spec

  # All the {.fails_with} for the currently active {SoftwareSpec}.
  delegate compiler_failures: :active_spec

  # If this {Formula} is installed.
  # This is actually just a check for if the {#installed_prefix} directory
  # exists and is not empty.
  # @private
  def installed?
    (dir = installed_prefix).directory? && !dir.children.empty?
  end

  # If at least one version of {Formula} is installed.
  # @private
  def any_version_installed?
    installed_prefixes.any? { |keg| (keg/Tab::FILENAME).file? }
  end

  # @private
  # The link status symlink directory for this {Formula}.
  # You probably want {#opt_prefix} instead.
  def linked_keg
    HOMEBREW_LINKED_KEGS/name
  end

  def latest_head_version
    head_versions = installed_prefixes.map do |pn|
      pn_pkgversion = PkgVersion.parse(pn.basename.to_s)
      pn_pkgversion if pn_pkgversion.head?
    end.compact

    head_versions.max_by do |pn_pkgversion|
      [Tab.for_keg(prefix(pn_pkgversion)).source_modified_time, pn_pkgversion.revision]
    end
  end

  def latest_head_prefix
    head_version = latest_head_version
    prefix(head_version) if head_version
  end

  def head_version_outdated?(version, options = {})
    tab = Tab.for_keg(prefix(version))

    return true if tab.version_scheme < version_scheme
    return true if stable && tab.stable_version && tab.stable_version < stable.version
    return true if devel && tab.devel_version && tab.devel_version < devel.version

    if options[:fetch_head]
      return false unless head&.downloader.is_a?(VCSDownloadStrategy)

      downloader = head.downloader
      downloader.shutup! unless ARGV.verbose?
      downloader.commit_outdated?(version.version.commit)
    else
      false
    end
  end

  # The latest prefix for this formula. Checks for {#head}, then {#devel}
  # and then {#stable}'s {#prefix}
  # @private
  def installed_prefix
    if head && (head_version = latest_head_version) && !head_version_outdated?(head_version)
      latest_head_prefix
    elsif devel && (devel_prefix = prefix(PkgVersion.new(devel.version, revision))).directory?
      devel_prefix
    elsif stable && (stable_prefix = prefix(PkgVersion.new(stable.version, revision))).directory?
      stable_prefix
    else
      prefix
    end
  end

  # The currently installed version for this formula. Will raise an exception
  # if the formula is not installed.
  # @private
  def installed_version
    Keg.new(installed_prefix).version
  end

  # The directory in the cellar that the formula is installed to.
  # This directory points to {#opt_prefix} if it exists and if #{prefix} is not
  # called from within the same formula's {#install} or {#post_install} methods.
  # Otherwise, return the full path to the formula's versioned cellar.
  def prefix(v = pkg_version)
    versioned_prefix = versioned_prefix(v)
    if !@prefix_returns_versioned_prefix && v == pkg_version &&
       versioned_prefix.directory? && Keg.new(versioned_prefix).optlinked?
      opt_prefix
    else
      versioned_prefix
    end
  end

  # Is the formula linked?
  def linked?
    linked_keg.symlink?
  end

  # Is the formula linked to `opt`?
  def optlinked?
    opt_prefix.symlink?
  end

  # If a formula's linked keg points to the prefix.
  def prefix_linked?(v = pkg_version)
    return false unless linked?

    linked_keg.resolved_path == versioned_prefix(v)
  end

  # {PkgVersion} of the linked keg for the formula.
  def linked_version
    return unless linked?

    Keg.for(linked_keg).version
  end

  # The parent of the prefix; the named directory in the cellar containing all
  # installed versions of this software
  # @private
  def rack
    Pathname.new("#{HOMEBREW_CELLAR}/#{name}")
  end

  # All currently installed prefix directories.
  # @private
  def installed_prefixes
    rack.directory? ? rack.subdirs.sort : []
  end

  # All currently installed kegs.
  # @private
  def installed_kegs
    installed_prefixes.map { |dir| Keg.new(dir) }
  end

  # The directory where the formula's binaries should be installed.
  # This is symlinked into `HOMEBREW_PREFIX` after installation or with
  # `brew link` for formulae that are not keg-only.
  #
  # Need to install into the {.bin} but the makefile doesn't `mkdir -p prefix/bin`?
  # <pre>bin.mkpath</pre>
  #
  # No `make install` available?
  # <pre>bin.install "binary1"</pre>
  def bin
    prefix/"bin"
  end

  # The directory where the formula's documentation should be installed.
  # This is symlinked into `HOMEBREW_PREFIX` after installation or with
  # `brew link` for formulae that are not keg-only.
  def doc
    share/"doc"/name
  end

  # The directory where the formula's headers should be installed.
  # This is symlinked into `HOMEBREW_PREFIX` after installation or with
  # `brew link` for formulae that are not keg-only.
  #
  # No `make install` available?
  # <pre>include.install "example.h"</pre>
  def include
    prefix/"include"
  end

  # The directory where the formula's info files should be installed.
  # This is symlinked into `HOMEBREW_PREFIX` after installation or with
  # `brew link` for formulae that are not keg-only.
  def info
    share/"info"
  end

  # The directory where the formula's libraries should be installed.
  # This is symlinked into `HOMEBREW_PREFIX` after installation or with
  # `brew link` for formulae that are not keg-only.
  #
  # No `make install` available?
  # <pre>lib.install "example.dylib"</pre>
  def lib
    prefix/"lib"
  end

  # The directory where the formula's binaries should be installed.
  # This is not symlinked into `HOMEBREW_PREFIX`.
  # It is also commonly used to install files that we do not wish to be
  # symlinked into `HOMEBREW_PREFIX` from one of the other directories and
  # instead manually create symlinks or wrapper scripts into e.g. {#bin}.
  def libexec
    prefix/"libexec"
  end

  # The root directory where the formula's manual pages should be installed.
  # This is symlinked into `HOMEBREW_PREFIX` after installation or with
  # `brew link` for formulae that are not keg-only.
  # Often one of the more specific `man` functions should be used instead,
  # e.g. {#man1}
  def man
    share/"man"
  end

  # The directory where the formula's man1 pages should be installed.
  # This is symlinked into `HOMEBREW_PREFIX` after installation or with
  # `brew link` for formulae that are not keg-only.
  #
  # No `make install` available?
  # <pre>man1.install "example.1"</pre>
  def man1
    man/"man1"
  end

  # The directory where the formula's man2 pages should be installed.
  # This is symlinked into `HOMEBREW_PREFIX` after installation or with
  # `brew link` for formulae that are not keg-only.
  def man2
    man/"man2"
  end

  # The directory where the formula's man3 pages should be installed.
  # This is symlinked into `HOMEBREW_PREFIX` after installation or with
  # `brew link` for formulae that are not keg-only.
  #
  # No `make install` available?
  # <pre>man3.install "man.3"</pre>
  def man3
    man/"man3"
  end

  # The directory where the formula's man4 pages should be installed.
  # This is symlinked into `HOMEBREW_PREFIX` after installation or with
  # `brew link` for formulae that are not keg-only.
  def man4
    man/"man4"
  end

  # The directory where the formula's man5 pages should be installed.
  # This is symlinked into `HOMEBREW_PREFIX` after installation or with
  # `brew link` for formulae that are not keg-only.
  def man5
    man/"man5"
  end

  # The directory where the formula's man6 pages should be installed.
  # This is symlinked into `HOMEBREW_PREFIX` after installation or with
  # `brew link` for formulae that are not keg-only.
  def man6
    man/"man6"
  end

  # The directory where the formula's man7 pages should be installed.
  # This is symlinked into `HOMEBREW_PREFIX` after installation or with
  # `brew link` for formulae that are not keg-only.
  def man7
    man/"man7"
  end

  # The directory where the formula's man8 pages should be installed.
  # This is symlinked into `HOMEBREW_PREFIX` after installation or with
  # `brew link` for formulae that are not keg-only.
  def man8
    man/"man8"
  end

  # The directory where the formula's `sbin` binaries should be installed.
  # This is symlinked into `HOMEBREW_PREFIX` after installation or with
  # `brew link` for formulae that are not keg-only.
  # Generally we try to migrate these to {#bin} instead.
  def sbin
    prefix/"sbin"
  end

  # The directory where the formula's shared files should be installed.
  # This is symlinked into `HOMEBREW_PREFIX` after installation or with
  # `brew link` for formulae that are not keg-only.
  #
  # Need a custom directory?
  # <pre>(share/"concept").mkpath</pre>
  #
  # Installing something into another custom directory?
  # <pre>(share/"concept2").install "ducks.txt"</pre>
  #
  # Install `./example_code/simple/ones` to share/demos
  # <pre>(share/"demos").install "example_code/simple/ones"</pre>
  #
  # Install `./example_code/simple/ones` to share/demos/examples
  # <pre>(share/"demos").install "example_code/simple/ones" => "examples"</pre>
  def share
    prefix/"share"
  end

  # The directory where the formula's shared files should be installed,
  # with the name of the formula appended to avoid linking conflicts.
  # This is symlinked into `HOMEBREW_PREFIX` after installation or with
  # `brew link` for formulae that are not keg-only.
  #
  # No `make install` available?
  # <pre>pkgshare.install "examples"</pre>
  def pkgshare
    prefix/"share"/name
  end

  # The directory where Emacs Lisp files should be installed, with the
  # formula name appended to avoid linking conflicts.
  #
  # Install an Emacs mode included with a software package:
  # <pre>elisp.install "contrib/emacs/example-mode.el"</pre>
  def elisp
    prefix/"share/emacs/site-lisp"/name
  end

  # The directory where the formula's Frameworks should be installed.
  # This is symlinked into `HOMEBREW_PREFIX` after installation or with
  # `brew link` for formulae that are not keg-only.
  # This is not symlinked into `HOMEBREW_PREFIX`.
  def frameworks
    prefix/"Frameworks"
  end

  # The directory where the formula's kernel extensions should be installed.
  # This is symlinked into `HOMEBREW_PREFIX` after installation or with
  # `brew link` for formulae that are not keg-only.
  # This is not symlinked into `HOMEBREW_PREFIX`.
  def kext_prefix
    prefix/"Library/Extensions"
  end

  # The directory where the formula's configuration files should be installed.
  # Anything using `etc.install` will not overwrite other files on e.g. upgrades
  # but will write a new file named `*.default`.
  # This directory is not inside the `HOMEBREW_CELLAR` so it persists
  # across upgrades.
  def etc
    (HOMEBREW_PREFIX/"etc").extend(InstallRenamed)
  end

  # The directory where the formula's variable files should be installed.
  # This directory is not inside the `HOMEBREW_CELLAR` so it persists
  # across upgrades.
  def var
    HOMEBREW_PREFIX/"var"
  end

  # The directory where the formula's ZSH function files should be
  # installed.
  # This is symlinked into `HOMEBREW_PREFIX` after installation or with
  # `brew link` for formulae that are not keg-only.
  def zsh_function
    share/"zsh/site-functions"
  end

  # The directory where the formula's fish function files should be
  # installed.
  # This is symlinked into `HOMEBREW_PREFIX` after installation or with
  # `brew link` for formulae that are not keg-only.
  def fish_function
    share/"fish/vendor_functions.d"
  end

  # The directory where the formula's Bash completion files should be
  # installed.
  # This is symlinked into `HOMEBREW_PREFIX` after installation or with
  # `brew link` for formulae that are not keg-only.
  def bash_completion
    prefix/"etc/bash_completion.d"
  end

  # The directory where the formula's ZSH completion files should be
  # installed.
  # This is symlinked into `HOMEBREW_PREFIX` after installation or with
  # `brew link` for formulae that are not keg-only.
  def zsh_completion
    share/"zsh/site-functions"
  end

  # The directory where the formula's fish completion files should be
  # installed.
  # This is symlinked into `HOMEBREW_PREFIX` after installation or with
  # `brew link` for formulae that are not keg-only.
  def fish_completion
    share/"fish/vendor_completions.d"
  end

  # The directory used for as the prefix for {#etc} and {#var} files on
  # installation so, despite not being in `HOMEBREW_CELLAR`, they are installed
  # there after pouring a bottle.
  # @private
  def bottle_prefix
    prefix/".bottle"
  end

  # The directory where the formula's installation or test logs will be written.
  # @private
  def logs
    HOMEBREW_LOGS + name
  end

  # The prefix, if any, to use in filenames for logging current activity
  def active_log_prefix
    if active_log_type
      "#{active_log_type}."
    else
      ""
    end
  end

  # Runs a block with the given log type in effect for its duration
  def with_logging(log_type)
    old_log_type = @active_log_type
    @active_log_type = log_type
    yield
  ensure
    @active_log_type = old_log_type
  end

  # This method can be overridden to provide a plist.
  # @see https://www.unix.com/man-page/all/5/plist/ Apple's plist(5) man page
  # <pre>def plist; <<~EOS
  #  <?xml version="1.0" encoding="UTF-8"?>
  #  <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
  #  <plist version="1.0">
  #  <dict>
  #    <key>Label</key>
  #      <string>#{plist_name}</string>
  #    <key>ProgramArguments</key>
  #    <array>
  #      <string>#{opt_bin}/example</string>
  #      <string>--do-this</string>
  #    </array>
  #    <key>RunAtLoad</key>
  #    <true/>
  #    <key>KeepAlive</key>
  #    <true/>
  #    <key>StandardErrorPath</key>
  #    <string>/dev/null</string>
  #    <key>StandardOutPath</key>
  #    <string>/dev/null</string>
  #  </dict>
  #  </plist>
  #  EOS
  # end</pre>
  def plist
    nil
  end

  # The generated launchd {.plist} service name.
  def plist_name
    "homebrew.mxcl." + name
  end

  # The generated launchd {.plist} file path.
  def plist_path
    prefix + (plist_name + ".plist")
  end

  # @private
  def plist_manual
    self.class.plist_manual
  end

  # @private
  def plist_startup
    self.class.plist_startup
  end

  # A stable path for this formula, when installed. Contains the formula name
  # but no version number. Only the active version will be linked here if
  # multiple versions are installed.
  #
  # This is the preferred way to refer to a formula in plists or from another
  # formula, as the path is stable even when the software is updated.
  # <pre>args << "--with-readline=#{Formula["readline"].opt_prefix}" if build.with? "readline"</pre>
  def opt_prefix
    Pathname.new("#{HOMEBREW_PREFIX}/opt/#{name}")
  end

  def opt_bin
    opt_prefix/"bin"
  end

  def opt_include
    opt_prefix/"include"
  end

  def opt_lib
    opt_prefix/"lib"
  end

  def opt_libexec
    opt_prefix/"libexec"
  end

  def opt_sbin
    opt_prefix/"sbin"
  end

  def opt_share
    opt_prefix/"share"
  end

  def opt_pkgshare
    opt_prefix/"share"/name
  end

  def opt_elisp
    opt_prefix/"share/emacs/site-lisp"/name
  end

  def opt_frameworks
    opt_prefix/"Frameworks"
  end

  # Indicates that this formula supports bottles. (Not necessarily that one
  # should be used in the current installation run.)
  # Can be overridden to selectively disable bottles from formulae.
  # Defaults to true so overridden version does not have to check if bottles
  # are supported.
  # Replaced by {.pour_bottle}'s `satisfy` method if it is specified.
  def pour_bottle?
    true
  end

  # @private
  def pour_bottle_check_unsatisfied_reason
    self.class.pour_bottle_check_unsatisfied_reason
  end

  # Can be overridden to run commands on both source and bottle installation.
  def post_install; end

  # @private
  def run_post_install
    @prefix_returns_versioned_prefix = true
    build = self.build
    self.build = Tab.for_formula(self)

    new_env = {
      "TMPDIR"        => HOMEBREW_TEMP,
      "TEMP"          => HOMEBREW_TEMP,
      "TMP"           => HOMEBREW_TEMP,
      "HOMEBREW_PATH" => nil,
      "PATH"          => ENV["HOMEBREW_PATH"],
    }

    with_env(new_env) do
      ENV.clear_sensitive_environment!

      Pathname.glob("#{bottle_prefix}/{etc,var}/**/*") do |path|
        path.extend(InstallRenamed)
        path.cp_path_sub(bottle_prefix, HOMEBREW_PREFIX)
      end

      with_logging("post_install") do
        post_install
      end
    end
  ensure
    self.build = build
    @prefix_returns_versioned_prefix = false
  end

  # Tell the user about any Homebrew-specific caveats or locations regarding
  # this package. These should not contain setup instructions that would apply
  # to installation through a different package manager on a different OS.
  # @return [String]
  # <pre>def caveats
  #   <<~EOS
  #     Are optional. Something the user should know?
  #   EOS
  # end</pre>
  #
  # <pre>def caveats
  #   s = <<~EOS
  #     Print some important notice to the user when `brew info [formula]` is
  #     called or when brewing a formula.
  #     This is optional. You can use all the vars like #{version} here.
  #   EOS
  #   s += "Some issue only on older systems" if MacOS.version < :mountain_lion
  #   s
  # end</pre>
  def caveats
    nil
  end

  # Rarely, you don't want your library symlinked into the main prefix.
  # See `gettext.rb` for an example.
  def keg_only?
    return false unless keg_only_reason

    keg_only_reason.valid?
  end

  # @private
  def keg_only_reason
    self.class.keg_only_reason
  end

  # sometimes the formula cleaner breaks things
  # skip cleaning paths in a formula with a class method like this:
  #   skip_clean "bin/foo", "lib/bar"
  # keep .la files with:
  #   skip_clean :la
  # @private
  def skip_clean?(path)
    return true if path.extname == ".la" && self.class.skip_clean_paths.include?(:la)

    to_check = path.relative_path_from(prefix).to_s
    self.class.skip_clean_paths.include? to_check
  end

  # Sometimes we accidentally install files outside prefix. After we fix that,
  # users will get nasty link conflict error. So we create a whitelist here to
  # allow overwriting certain files. e.g.
  #   link_overwrite "bin/foo", "lib/bar"
  #   link_overwrite "share/man/man1/baz-*"
  # @private
  def link_overwrite?(path)
    # Don't overwrite files not created by Homebrew.
    return false unless path.stat.uid == HOMEBREW_BREW_FILE.stat.uid

    # Don't overwrite files belong to other keg except when that
    # keg's formula is deleted.
    begin
      keg = Keg.for(path)
    rescue NotAKegError, Errno::ENOENT # rubocop:disable Lint/HandleExceptions
      # file doesn't belong to any keg.
    else
      tab_tap = Tab.for_keg(keg).tap
      # this keg doesn't below to any core/tap formula, most likely coming from a DIY install.
      return false if tab_tap.nil?

      begin
        Formulary.factory(keg.name)
      rescue FormulaUnavailableError # rubocop:disable Lint/HandleExceptions
        # formula for this keg is deleted, so defer to whitelist
      rescue TapFormulaAmbiguityError, TapFormulaWithOldnameAmbiguityError
        return false # this keg belongs to another formula
      else
        return false # this keg belongs to another formula
      end
    end
    to_check = path.relative_path_from(HOMEBREW_PREFIX).to_s
    self.class.link_overwrite_paths.any? do |p|
      p == to_check ||
        to_check.start_with?(p.chomp("/") + "/") ||
        to_check =~ /^#{Regexp.escape(p).gsub('\*', ".*?")}$/
    end
  end

  def skip_cxxstdlib_check?
    false
  end

  # @private
  def require_universal_deps?
    false
  end

  # @private
  def patch
    return if patchlist.empty?

    ohai "Patching"
    patchlist.each(&:apply)
  end

  # yields |self,staging| with current working directory set to the uncompressed tarball
  # where staging is a Mktemp staging context
  # @private
  def brew
    @prefix_returns_versioned_prefix = true
    stage do |staging|
      staging.retain! if ARGV.keep_tmp?
      prepare_patches

      begin
        yield self, staging
      rescue
        staging.retain! if ARGV.interactive? || ARGV.debug?
        raise
      ensure
        cp Dir["config.log", "CMakeCache.txt"], logs
      end
    end
  ensure
    @prefix_returns_versioned_prefix = false
  end

  # @private
  def lock
    @lock = FormulaLock.new(name)
    @lock.lock
    return unless oldname
    return unless (oldname_rack = HOMEBREW_CELLAR/oldname).exist?
    return unless oldname_rack.resolved_path == rack

    @oldname_lock = FormulaLock.new(oldname)
    @oldname_lock.lock
  end

  # @private
  def unlock
    @lock&.unlock
    @oldname_lock&.unlock
  end

  def migration_needed?
    return false unless oldname
    return false if rack.exist?

    old_rack = HOMEBREW_CELLAR/oldname
    return false unless old_rack.directory?
    return false if old_rack.subdirs.empty?

    tap == Tab.for_keg(old_rack.subdirs.min).tap
  end

  # @private
  def outdated_kegs(options = {})
    @outdated_kegs ||= Hash.new do |cache, key|
      raise Migrator::MigrationNeededError, self if migration_needed?

      cache[key] = _outdated_kegs(key)
    end
    @outdated_kegs[options]
  end

  def _outdated_kegs(options = {})
    all_kegs = []

    installed_kegs.each do |keg|
      all_kegs << keg
      version = keg.version
      next if version.head?

      tab = Tab.for_keg(keg)
      next if version_scheme > tab.version_scheme
      next if version_scheme == tab.version_scheme && pkg_version > version

      # don't consider this keg current if there's a newer formula available
      next if follow_installed_alias? && new_formula_available?

      return [] # this keg is the current version of the formula, so it's not outdated
    end

    # Even if this formula hasn't been installed, there may be installations
    # of other formulae which used to be targets of the alias currently
    # targetting this formula. These should be counted as outdated versions.
    all_kegs.concat old_installed_formulae.flat_map(&:installed_kegs)

    head_version = latest_head_version
    if head_version && !head_version_outdated?(head_version, options)
      []
    else
      all_kegs.sort_by(&:version)
    end
  end

  def new_formula_available?
    installed_alias_target_changed? && !latest_formula.installed?
  end

  def current_installed_alias_target
    Formulary.factory(installed_alias_path) if installed_alias_path
  end

  # Has the target of the alias used to install this formula changed?
  # Returns false if the formula wasn't installed with an alias.
  def installed_alias_target_changed?
    target = current_installed_alias_target
    return false unless target

    target.name != name
  end

  # Is this formula the target of an alias used to install an old formula?
  def supersedes_an_installed_formula?
    old_installed_formulae.any?
  end

  # Has the alias used to install the formula changed, or are different
  # formulae already installed with this alias?
  def alias_changed?
    installed_alias_target_changed? || supersedes_an_installed_formula?
  end

  # If the alias has changed value, return the new formula.
  # Otherwise, return self.
  def latest_formula
    installed_alias_target_changed? ? current_installed_alias_target : self
  end

  def old_installed_formulae
    # If this formula isn't the current target of the alias,
    # it doesn't make sense to say that other formulae are older versions of it
    # because we don't know which came first.
    return [] if alias_path.nil? || installed_alias_target_changed?

    self.class.installed_with_alias_path(alias_path).reject { |f| f.name == name }
  end

  # @private
  def outdated?(options = {})
    !outdated_kegs(options).empty?
  rescue Migrator::MigrationNeededError
    true
  end

  # @private
  def pinnable?
    @pin.pinnable?
  end

  # @private
  def pinned?
    @pin.pinned?
  end

  # @private
  def pinned_version
    @pin.pinned_version
  end

  # @private
  def pin
    @pin.pin
  end

  # @private
  def unpin
    @pin.unpin
  end

  # @private
  def ==(other)
    instance_of?(other.class) &&
      name == other.name &&
      active_spec == other.active_spec
  end
  alias eql? ==

  # @private
  def hash
    name.hash
  end

  # @private
  def <=>(other)
    return unless other.is_a?(Formula)

    name <=> other.name
  end

  def to_s
    name
  end

  # @private
  def inspect
    "#<Formula #{name} (#{active_spec_sym}) #{path}>"
  end

  # Standard parameters for CMake builds.
  # Setting `CMAKE_FIND_FRAMEWORK` to "LAST" tells CMake to search for our
  # libraries before trying to utilize Frameworks, many of which will be from
  # 3rd party installs.
  # Note: there isn't a std_autotools variant because autotools is a lot
  # less consistent and the standard parameters are more memorable.
  def std_cmake_args
    args = %W[
      -DCMAKE_C_FLAGS_RELEASE=-DNDEBUG
      -DCMAKE_CXX_FLAGS_RELEASE=-DNDEBUG
      -DCMAKE_INSTALL_PREFIX=#{prefix}
      -DCMAKE_BUILD_TYPE=Release
      -DCMAKE_FIND_FRAMEWORK=LAST
      -DCMAKE_VERBOSE_MAKEFILE=ON
      -Wno-dev
    ]

    # Avoid false positives for clock_gettime support on 10.11.
    # CMake cache entries for other weak symbols may be added here as needed.
    if MacOS.version == "10.11" && MacOS::Xcode.version >= "8.0"
      args << "-DHAVE_CLOCK_GETTIME:INTERNAL=0"
    end

    args
  end

  # an array of all core {Formula} names
  # @private
  def self.core_names
    CoreTap.instance.formula_names
  end

  # an array of all core {Formula} files
  # @private
  def self.core_files
    CoreTap.instance.formula_files
  end

  # an array of all tap {Formula} names
  # @private
  def self.tap_names
    @tap_names ||= Tap.reject(&:core_tap?).flat_map(&:formula_names).sort
  end

  # an array of all tap {Formula} files
  # @private
  def self.tap_files
    @tap_files ||= Tap.reject(&:core_tap?).flat_map(&:formula_files)
  end

  # an array of all {Formula} names
  # @private
  def self.names
    @names ||= (core_names + tap_names.map { |name| name.split("/").last }).uniq.sort
  end

  # an array of all {Formula} files
  # @private
  def self.files
    @files ||= core_files + tap_files
  end

  # an array of all {Formula} names, which the tap formulae have the fully-qualified name
  # @private
  def self.full_names
    @full_names ||= core_names + tap_names
  end

  # @private
  def self.each
    files.each do |file|
      begin
        yield Formulary.factory(file)
      rescue => e
        # Don't let one broken formula break commands. But do complain.
        onoe "Failed to import: #{file}"
        puts e
        next
      end
    end
  end

  # Clear cache of .racks
  def self.clear_racks_cache
    @racks = nil
  end

  # Clear caches of .racks and .installed.
  def self.clear_installed_formulae_cache
    clear_racks_cache
    @installed = nil
  end

  # An array of all racks currently installed.
  # @private
  def self.racks
    @racks ||= if HOMEBREW_CELLAR.directory?
      HOMEBREW_CELLAR.subdirs.reject do |rack|
        rack.symlink? || rack.basename.to_s.start_with?(".") || rack.subdirs.empty?
      end
    else
      []
    end
  end

  # An array of all installed {Formula}
  # @private
  def self.installed
    @installed ||= racks.flat_map do |rack|
      begin
        Formulary.from_rack(rack)
      rescue FormulaUnavailableError, TapFormulaAmbiguityError, TapFormulaWithOldnameAmbiguityError
        []
      end
    end.uniq(&:name)
  end

  def self.installed_with_alias_path(alias_path)
    return [] if alias_path.nil?

    installed.select { |f| f.installed_alias_path == alias_path }
  end

  # an array of all alias files of core {Formula}
  # @private
  def self.core_alias_files
    CoreTap.instance.alias_files
  end

  # an array of all core aliases
  # @private
  def self.core_aliases
    CoreTap.instance.aliases
  end

  # an array of all tap aliases
  # @private
  def self.tap_aliases
    @tap_aliases ||= Tap.reject(&:core_tap?).flat_map(&:aliases).sort
  end

  # an array of all aliases
  # @private
  def self.aliases
    @aliases ||= (core_aliases + tap_aliases.map { |name| name.split("/").last }).uniq.sort
  end

  # an array of all aliases, , which the tap formulae have the fully-qualified name
  # @private
  def self.alias_full_names
    @alias_full_names ||= core_aliases + tap_aliases
  end

  # a table mapping core alias to formula name
  # @private
  def self.core_alias_table
    CoreTap.instance.alias_table
  end

  # a table mapping core formula name to aliases
  # @private
  def self.core_alias_reverse_table
    CoreTap.instance.alias_reverse_table
  end

  def self.[](name)
    Formulary.factory(name)
  end

  # True if this formula is provided by Homebrew itself
  # @private
  def core_formula?
    tap&.core_tap?
  end

  # True if this formula is provided by external Tap
  # @private
  def tap?
    return false unless tap

    !tap.core_tap?
  end

  # @private
  def print_tap_action(options = {})
    return unless tap?

    verb = options[:verb] || "Installing"
    ohai "#{verb} #{name} from #{tap}"
  end

  # @private
  def env
    self.class.env
  end

  # @private
  def conflicts
    self.class.conflicts
  end

  # Returns a list of Dependency objects in an installable order, which
  # means if a depends on b then b will be ordered before a in this list
  # @private
  def recursive_dependencies(&block)
    Dependency.expand(self, &block)
  end

  # The full set of Requirements for this formula's dependency tree.
  # @private
  def recursive_requirements(&block)
    Requirement.expand(self, &block)
  end

  # Returns a Keg for the opt_prefix or installed_prefix if they exist.
  # If not, return nil.
  # @private
  def opt_or_installed_prefix_keg
    if optlinked? && opt_prefix.exist?
      Keg.new(opt_prefix)
    elsif installed_prefix.directory?
      Keg.new(installed_prefix)
    end
  end

  # Returns a list of Dependency objects that are required at runtime.
  # @private
  def runtime_dependencies(read_from_tab: true, undeclared: true)
    if read_from_tab &&
       undeclared &&
       (keg = opt_or_installed_prefix_keg) &&
       (tab_deps = keg.runtime_dependencies)
      return tab_deps.map do |d|
        full_name = d["full_name"]
        next unless full_name

        Dependency.new full_name
      end.compact
    end

    return declared_runtime_dependencies unless undeclared

    declared_runtime_dependencies | undeclared_runtime_dependencies
  end

  # Returns a list of Formula objects that are required at runtime.
  # @private
  def runtime_formula_dependencies(read_from_tab: true, undeclared: true)
    runtime_dependencies(
      read_from_tab: read_from_tab,
      undeclared:    undeclared,
    ).map do |d|
      begin
        d.to_formula
      rescue FormulaUnavailableError
        nil
      end
    end.compact
  end

  # Returns a list of formulae depended on by this formula that aren't
  # installed
  def missing_dependencies(hide: nil)
    hide ||= []
    runtime_formula_dependencies.select do |f|
      hide.include?(f.name) || f.installed_prefixes.empty?
    end
  # If we're still getting unavailable formulae at this stage the best we can
  # do is just return no results.
  rescue FormulaUnavailableError
    []
  end

  # @private
  def to_hash
    dependencies = deps

    hsh = {
      "name"                     => name,
      "full_name"                => full_name,
      "oldname"                  => oldname,
      "aliases"                  => aliases.sort,
      "versioned_formulae"       => versioned_formulae.map(&:name),
      "desc"                     => desc,
      "homepage"                 => homepage,
      "versions"                 => {
        "stable" => stable&.version&.to_s,
        "devel"  => devel&.version&.to_s,
        "head"   => head&.version&.to_s,
        "bottle" => !bottle_specification.checksums.empty?,
      },
      "revision"                 => revision,
      "version_scheme"           => version_scheme,
      "bottle"                   => {},
      "keg_only"                 => keg_only?,
      "options"                  => [],
      "build_dependencies"       => dependencies.select(&:build?)
                                                .map(&:name)
                                                .uniq,
      "dependencies"             => dependencies.reject(&:optional?)
                                                .reject(&:recommended?)
                                                .reject(&:build?)
                                                .map(&:name)
                                                .uniq,
      "recommended_dependencies" => dependencies.select(&:recommended?)
                                                .map(&:name)
                                                .uniq,
      "optional_dependencies"    => dependencies.select(&:optional?)
                                                .map(&:name)
                                                .uniq,
      "requirements"             => [],
      "conflicts_with"           => conflicts.map(&:name),
      "caveats"                  => caveats,
      "installed"                => [],
      "linked_keg"               => linked_version&.to_s,
      "pinned"                   => pinned?,
      "outdated"                 => outdated?,
    }

    %w[stable devel].each do |spec_sym|
      next unless spec = send(spec_sym)
      next unless spec.bottle_defined?

      bottle_spec = spec.bottle_specification
      bottle_info = {
        "rebuild"  => bottle_spec.rebuild,
        "cellar"   => (cellar = bottle_spec.cellar).is_a?(Symbol) ? cellar.inspect : cellar,
        "prefix"   => bottle_spec.prefix,
        "root_url" => bottle_spec.root_url,
      }
      bottle_info["files"] = {}
      bottle_spec.collector.keys.each do |os|
        bottle_url = "#{bottle_spec.root_url}/#{Bottle::Filename.create(self, os, bottle_spec.rebuild).bintray}"
        checksum = bottle_spec.collector[os]
        bottle_info["files"][os] = {
          "url"                   => bottle_url,
          checksum.hash_type.to_s => checksum.hexdigest,
        }
      end
      hsh["bottle"][spec_sym] = bottle_info
    end

    hsh["options"] = options.map do |opt|
      { "option" => opt.flag, "description" => opt.description }
    end

    hsh["requirements"] = requirements.map do |req|
      {
        "name"     => req.name,
        "cask"     => req.cask,
        "download" => req.download,
      }
    end

    installed_kegs.each do |keg|
      tab = Tab.for_keg keg

      hsh["installed"] << {
        "version"                 => keg.version.to_s,
        "used_options"            => tab.used_options.as_flags,
        "built_as_bottle"         => tab.built_as_bottle,
        "poured_from_bottle"      => tab.poured_from_bottle,
        "runtime_dependencies"    => tab.runtime_dependencies,
        "installed_as_dependency" => tab.installed_as_dependency,
        "installed_on_request"    => tab.installed_on_request,
      }
    end

    hsh["installed"] = hsh["installed"].sort_by { |i| Version.create(i["version"]) }

    hsh
  end

  # @private
  def fetch
    active_spec.fetch
  end

  # @private
  def verify_download_integrity(fn)
    active_spec.verify_download_integrity(fn)
  end

  # @private
  def run_test
    @prefix_returns_versioned_prefix = true

    test_env = {
      CURL_HOME:     ENV["CURL_HOME"] || ENV["HOME"],
      TMPDIR:        HOMEBREW_TEMP,
      TEMP:          HOMEBREW_TEMP,
      TMP:           HOMEBREW_TEMP,
      TERM:          "dumb",
      PATH:          PATH.new(ENV["PATH"], HOMEBREW_PREFIX/"bin"),
      HOMEBREW_PATH: nil,
      _JAVA_OPTIONS: "#{ENV["_JAVA_OPTIONS"]} -Duser.home=#{HOMEBREW_CACHE}/java_cache",
      GOCACHE:       "#{HOMEBREW_CACHE}/go_cache",
      CARGO_HOME:    "#{HOMEBREW_CACHE}/cargo_cache",
    }

    ENV.clear_sensitive_environment!

    mktemp("#{name}-test") do |staging|
      staging.retain! if ARGV.keep_tmp?
      @testpath = staging.tmpdir
      test_env[:HOME] = @testpath
      setup_home @testpath
      begin
        with_logging("test") do
          with_env(test_env) do
            test
          end
        end
      rescue Exception # rubocop:disable Lint/RescueException
        staging.retain! if ARGV.debug?
        raise
      end
    end
  ensure
    @testpath = nil
    @prefix_returns_versioned_prefix = false
  end

  # @private
  def test_defined?
    false
  end

  # @private
  def test; end

  # @private
  def test_fixtures(file)
    HOMEBREW_LIBRARY_PATH/"test/support/fixtures"/file
  end

  # This method is overridden in {Formula} subclasses to provide the installation instructions.
  # The sources (from {.url}) are downloaded, hash-checked and
  # Homebrew changes into a temporary directory where the
  # archive was unpacked or repository cloned.
  # <pre>def install
  #   system "./configure", "--prefix=#{prefix}"
  #   system "make", "install"
  # end</pre>
  def install; end

  protected

  def setup_home(home)
    # keep Homebrew's site-packages in sys.path when using system Python
    user_site_packages = home/"Library/Python/2.7/lib/python/site-packages"
    user_site_packages.mkpath
    (user_site_packages/"homebrew.pth").write <<~PYTHON
      import site; site.addsitedir("#{HOMEBREW_PREFIX}/lib/python2.7/site-packages")
      import sys, os; sys.path = (os.environ["PYTHONPATH"].split(os.pathsep) if "PYTHONPATH" in os.environ else []) + ["#{HOMEBREW_PREFIX}/lib/python2.7/site-packages"] + sys.path
    PYTHON
  end

  # Returns a list of Dependency objects that are declared in the formula.
  # @private
  def declared_runtime_dependencies
    recursive_dependencies do |_, dependency|
      Dependency.prune if dependency.build?
      next if dependency.required?

      if build.any_args_or_options?
        Dependency.prune if build.without?(dependency)
      elsif !dependency.recommended?
        Dependency.prune
      end
    end
  end

  # Returns a list of Dependency objects that are not declared in the formula
  # but the formula links to.
  # @private
  def undeclared_runtime_dependencies
    keg = opt_or_installed_prefix_keg
    return [] unless keg

    undeclared_deps = CacheStoreDatabase.use(:linkage) do |db|
      linkage_checker = LinkageChecker.new(keg, self, cache_db: db)
      linkage_checker.undeclared_deps.map { |n| Dependency.new(n) }
    end

    undeclared_deps
  end

  public

  # To call out to the system, we use the `system` method and we prefer
  # you give the args separately as in the line below, otherwise a subshell
  # has to be opened first.
  # <pre>system "./bootstrap.sh", "--arg1", "--prefix=#{prefix}"</pre>
  #
  # For CMake we have some necessary defaults in {#std_cmake_args}:
  # <pre>system "cmake", ".", *std_cmake_args</pre>
  #
  # If the arguments given to configure (or make or cmake) are depending
  # on options defined above, we usually make a list first and then
  # use the `args << if <condition>` to append to:
  # <pre>args = ["--with-option1", "--with-option2"]
  #
  # # Most software still uses `configure` and `make`.
  # # Check with `./configure --help` what our options are.
  # system "./configure", "--disable-debug", "--disable-dependency-tracking",
  #                       "--disable-silent-rules", "--prefix=#{prefix}",
  #                       *args # our custom arg list (needs `*` to unpack)
  #
  # # If there is a "make", "install" available, please use it!
  # system "make", "install"</pre>
  def system(cmd, *args)
    verbose = ARGV.verbose?
    verbose_using_dots = !ENV["HOMEBREW_VERBOSE_USING_DOTS"].nil?

    # remove "boring" arguments so that the important ones are more likely to
    # be shown considering that we trim long ohai lines to the terminal width
    pretty_args = args.dup
    if cmd == "./configure" && !verbose
      pretty_args.delete "--disable-dependency-tracking"
      pretty_args.delete "--disable-debug"
    end
    pretty_args.each_index do |i|
      if pretty_args[i].to_s.start_with? "import setuptools"
        pretty_args[i] = "import setuptools..."
      end
    end
    ohai "#{cmd} #{pretty_args * " "}".strip

    @exec_count ||= 0
    @exec_count += 1
    logfn = format("#{logs}/#{active_log_prefix}%02<exec_count>d.%{cmd_base}",
                   exec_count: @exec_count,
                   cmd_base:   File.basename(cmd).split(" ").first)
    logs.mkpath

    File.open(logfn, "w") do |log|
      log.puts Time.now, "", cmd, args, ""
      log.flush

      if verbose
        rd, wr = IO.pipe
        begin
          pid = fork do
            rd.close
            log.close
            exec_cmd(cmd, args, wr, logfn)
          end
          wr.close

          if verbose_using_dots
            last_dot = Time.at(0)
            while buf = rd.gets
              log.puts buf
              # make sure dots printed with interval of at least 1 min.
              next unless (Time.now - last_dot) > 60

              print "."
              $stdout.flush
              last_dot = Time.now
            end
            puts
          else
            while buf = rd.gets
              log.puts buf
              puts buf
            end
          end
        ensure
          rd.close
        end
      else
        pid = fork { exec_cmd(cmd, args, log, logfn) }
      end

      Process.wait(pid)

      $stdout.flush

      unless $CHILD_STATUS.success?
        log_lines = ENV["HOMEBREW_FAIL_LOG_LINES"]
        log_lines ||= "15"

        log.flush
        if !verbose || verbose_using_dots
          puts "Last #{log_lines} lines from #{logfn}:"
          Kernel.system "/usr/bin/tail", "-n", log_lines, logfn
        end
        log.puts

        require "system_config"
        require "build_environment"

        env = ENV.to_hash

        SystemConfig.dump_verbose_config(log)
        log.puts
        Homebrew.dump_build_env(env, log)

        raise BuildError.new(self, cmd, args, env)
      end
    end
  end

  # @private
  def eligible_kegs_for_cleanup
    eligible_for_cleanup = []
    if installed?
      eligible_kegs = if head? && (head_prefix = latest_head_prefix)
        installed_kegs - [Keg.new(head_prefix)]
      else
        installed_kegs.select do |keg|
          tab = Tab.for_keg(keg)
          if version_scheme > tab.version_scheme
            true
          elsif version_scheme == tab.version_scheme
            pkg_version > keg.version
          else
            false
          end
        end
      end

      unless eligible_kegs.empty?
        eligible_kegs.each do |keg|
          if keg.linked?
            opoo "Skipping (old) #{keg} due to it being linked"
          elsif pinned? && keg == Keg.new(@pin.path.resolved_path)
            opoo "Skipping (old) #{keg} due to it being pinned"
          else
            eligible_for_cleanup << keg
          end
        end
      end
    elsif !installed_prefixes.empty? && !pinned?
      # If the cellar only has one version installed, don't complain
      # that we can't tell which one to keep. Don't complain at all if the
      # only installed version is a pinned formula.
      opoo "Skipping #{full_name}: most recent version #{pkg_version} not installed"
    end
    eligible_for_cleanup
  end

  # Create a temporary directory then yield. When the block returns,
  # recursively delete the temporary directory. Passing `opts[:retain]`
  # or calling `do |staging| ... staging.retain!` in the block will skip
  # the deletion and retain the temporary directory's contents.
  def mktemp(prefix = name, opts = {})
    Mktemp.new(prefix, opts).run do |staging|
      yield staging
    end
  end

  # A version of `FileUtils.mkdir` that also changes to that folder in
  # a block.
  def mkdir(name)
    result = FileUtils.mkdir_p(name)
    return result unless block_given?

    FileUtils.chdir name do
      yield
    end
  end

  # Run `scons` using a Homebrew-installed version rather than whatever is
  # in the `PATH`.
  def scons(*args)
    system Formulary.factory("scons").opt_bin/"scons", *args
  end

  # Run `make` 3.81 or newer.
  # Uses the system make on Leopard and newer, and the
  # path to the actually-installed make on Tiger or older.
  def make(*args)
    if Utils.popen_read("/usr/bin/make", "--version")
            .match(/Make (\d\.\d+)/)[1] > "3.80"
      make_path = "/usr/bin/make"
    else
      make = Formula["make"].opt_bin/"make"
      make_path = if make.exist?
        make.to_s
      else
        (Formula["make"].opt_bin/"gmake").to_s
      end
    end

    if superenv?
      make_name = File.basename(make_path)
      with_env(HOMEBREW_MAKE: make_name) do
        system "make", *args
      end
    else
      system make_path, *args
    end
  end

  # Run `xcodebuild` without Homebrew's compiler environment variables set.
  def xcodebuild(*args)
    removed = ENV.remove_cc_etc
    system "xcodebuild", *args
  ensure
    ENV.update(removed)
  end

  private

  # Returns the prefix for a given formula version number.
  # @private
  def versioned_prefix(v)
    rack/v
  end

  def exec_cmd(cmd, args, out, logfn)
    ENV["HOMEBREW_CC_LOG_PATH"] = logfn

    ENV.remove_cc_etc if cmd.to_s.start_with? "xcodebuild"

    # Turn on argument filtering in the superenv compiler wrapper.
    # We should probably have a better mechanism for this than adding
    # special cases to this method.
    if cmd == "python"
      setup_py_in_args = %w[setup.py build.py].include?(args.first)
      setuptools_shim_in_args = args.any? { |a| a.to_s.start_with? "import setuptools" }
      ENV.refurbish_args if setup_py_in_args || setuptools_shim_in_args
    end

    $stdout.reopen(out)
    $stderr.reopen(out)
    out.close
    args.map!(&:to_s)
    begin
      exec(cmd, *args)
    rescue
      nil
    end
    puts "Failed to execute: #{cmd}"
    exit! 1 # never gets here unless exec threw or failed
  end

  def stage
    active_spec.stage do |staging|
      @source_modified_time = active_spec.source_modified_time
      @buildpath = Pathname.pwd
      env_home = buildpath/".brew_home"
      mkdir_p env_home

      stage_env = {
        HOMEBREW_PATH: nil,
      }

      unless ARGV.interactive?
        stage_env[:HOME] = env_home
        stage_env[:_JAVA_OPTIONS] =
          "#{ENV["_JAVA_OPTIONS"]} -Duser.home=#{HOMEBREW_CACHE}/java_cache"
        stage_env[:GOCACHE] = "#{HOMEBREW_CACHE}/go_cache"
        stage_env[:CARGO_HOME] = "#{HOMEBREW_CACHE}/cargo_cache"
        stage_env[:CURL_HOME] = ENV["CURL_HOME"] || ENV["HOME"]
      end

      setup_home env_home

      ENV.clear_sensitive_environment!

      begin
        with_env(stage_env) do
          yield staging
        end
      ensure
        @buildpath = nil
      end
    end
  end

  def prepare_patches
    active_spec.add_legacy_patches(patches) if respond_to?(:patches)

    patchlist.grep(DATAPatch) { |p| p.path = path }

    patchlist.each do |patch|
      patch.verify_download_integrity(patch.fetch) if patch.external?
    end
  end

  # The methods below define the formula DSL.
  class << self
    include BuildEnvironment::DSL

    def method_added(method)
      case method
      when :brew
        raise "You cannot override Formula#brew in class #{name}"
      when :test
        define_method(:test_defined?) { true }
      when :options
        instance = allocate

        specs.each do |spec|
          instance.options.each do |opt, desc|
            spec.option(opt[/^--(.+)$/, 1], desc)
          end
        end

        remove_method(:options)
      end
    end

    # The reason for why this software is not linked (by default) to
    # {::HOMEBREW_PREFIX}.
    # @private
    attr_reader :keg_only_reason

    # @!attribute [w]
    # A one-line description of the software. Used by users to get an overview
    # of the software and Homebrew maintainers.
    # Shows when running `brew info`.
    #
    # <pre>desc "Example formula"</pre>
    attr_rw :desc

    # @!attribute [w] homepage
    # The homepage for the software. Used by users to get more information
    # about the software and Homebrew maintainers as a point of contact for
    # e.g. submitting patches.
    # Can be opened with running `brew home`.
    #
    # <pre>homepage "https://www.example.com"</pre>
    attr_rw :homepage

    # The `:startup` attribute set by {.plist_options}.
    # @private
    attr_reader :plist_startup

    # The `:manual` attribute set by {.plist_options}.
    # @private
    attr_reader :plist_manual

    # If `pour_bottle?` returns `false` the user-visible reason to display for
    # why they cannot use the bottle.
    # @private
    attr_accessor :pour_bottle_check_unsatisfied_reason

    # @!attribute [w] revision
    # Used for creating new Homebrew versions of software without new upstream
    # versions. For example, if we bump the major version of a library this
    # {Formula} {.depends_on} then we may need to update the `revision` of this
    # {Formula} to install a new version linked against the new library version.
    # `0` if unset.
    #
    # <pre>revision 1</pre>
    attr_rw :revision

    # @!attribute [w] version_scheme
    # Used for creating new Homebrew version schemes. For example, if we want
    # to change version scheme from one to another, then we may need to update
    # `version_scheme` of this {Formula} to be able to use new version scheme.
    # e.g. to move from 20151020 scheme to 1.0.0 we need to increment
    # `version_scheme`. Without this, the prior scheme will always equate to a
    # higher version.
    # `0` if unset.
    #
    # <pre>version_scheme 1</pre>
    attr_rw :version_scheme

    # A list of the {.stable}, {.devel} and {.head} {SoftwareSpec}s.
    # @private
    def specs
      @specs ||= [stable, devel, head].freeze
    end

    # @!attribute [w] url
    # The URL used to download the source for the {.stable} version of the formula.
    # We prefer `https` for security and proxy reasons.
    # If not inferrable, specify the download strategy with `:using => ...`
    #
    # - `:git`, `:hg`, `:svn`, `:bzr`, `:fossil`, `:cvs`,
    # - `:curl` (normal file download. Will also extract.)
    # - `:nounzip` (without extracting)
    # - `:post` (download via an HTTP POST)
    # - `:s3` (download from S3 using signed request)
    #
    # <pre>url "https://packed.sources.and.we.prefer.https.example.com/archive-1.2.3.tar.bz2"</pre>
    # <pre>url "https://some.dont.provide.archives.example.com",
    #     :using => :git,
    #     :tag => "1.2.3",
    #     :revision => "db8e4de5b2d6653f66aea53094624468caad15d2"</pre>
    def url(val, specs = {})
      stable.url(val, specs)
    end

    # @!attribute [w] version
    # The version string for the {.stable} version of the formula.
    # The version is autodetected from the URL and/or tag so only needs to be
    # declared if it cannot be autodetected correctly.
    #
    # <pre>version "1.2-final"</pre>
    def version(val = nil)
      stable.version(val)
    end

    # @!attribute [w] mirror
    # Additional URLs for the {.stable} version of the formula.
    # These are only used if the {.url} fails to download. It's optional and
    # there can be more than one. Generally we add them when the main {.url}
    # is unreliable. If {.url} is really unreliable then we may swap the
    # {.mirror} and {.url}.
    #
    # <pre>mirror "https://in.case.the.host.is.down.example.com"
    # mirror "https://in.case.the.mirror.is.down.example.com</pre>
    def mirror(val)
      stable.mirror(val)
    end

    # @!attribute [w] sha256
    # @scope class
    # To verify the cached download's integrity and security we verify the
    # SHA-256 hash matches which we've declared in the {Formula}. To quickly fill
    # this value you can leave it blank and run `brew fetch --force` and it'll
    # tell you the currently valid value.
    #
    # <pre>sha256 "2a2ba417eebaadcb4418ee7b12fe2998f26d6e6f7fda7983412ff66a741ab6f7"</pre>
    Checksum::TYPES.each do |type|
      define_method(type) { |val| stable.send(type, val) }
    end

    # @!attribute [w] bottle
    # Adds a {.bottle} {SoftwareSpec}.
    # This provides a pre-built binary package built by the Homebrew maintainers for you.
    # It will be installed automatically if there is a binary package for your platform
    # and you haven't passed or previously used any options on this formula.
    #
    # If you maintain your own repository, you can add your own bottle links.
    # @see https://docs.brew.sh/Bottles
    # You can ignore this block entirely if submitting to Homebrew/homebrew-core.
    # It'll be handled for you by the Brew Test Bot.
    #
    # <pre>bottle do
    #   root_url "https://example.com" # Optional root to calculate bottle URLs
    #   prefix "/opt/homebrew" # Optional HOMEBREW_PREFIX in which the bottles were built.
    #   cellar "/opt/homebrew/Cellar" # Optional HOMEBREW_CELLAR in which the bottles were built.
    #   rebuild 1 # Making the old bottle outdated without bumping the version/revision of the formula.
    #   sha256 "4355a46b19d348dc2f57c046f8ef63d4538ebb936000f3c9ee954a27460dd865" => :el_capitan
    #   sha256 "53c234e5e8472b6ac51c1ae1cab3fe06fad053beb8ebfd8977b010655bfdd3c3" => :yosemite
    #   sha256 "1121cfccd5913f0a63fec40a6ffd44ea64f9dc135c66634ba001d10bcf4302a2" => :mavericks
    # end</pre>
    #
    # Only formulae where the upstream URL breaks or moves frequently, require compiling
    # or have a reasonable amount of patches/resources should be bottled.
    # Formulae which do not meet the above requirements should not be bottled.
    #
    # Formulae which should not be bottled and can be installed without any compile
    # required should be tagged with:
    # <pre>bottle :unneeded</pre>
    #
    # Otherwise formulae which do not meet the above requirements and should not
    # be bottled should be tagged with:
    # <pre>bottle :disable, "reasons"</pre>
    def bottle(*args, &block)
      stable.bottle(*args, &block)
    end

    # @private
    def build
      stable.build
    end

    # @!attribute [w] stable
    # Allows adding {.depends_on} and {Patch}es just to the {.stable} {SoftwareSpec}.
    # This is required instead of using a conditional.
    # It is preferrable to also pull the {url} and {.sha256} into the block if one is added.
    #
    # <pre>stable do
    #   url "https://example.com/foo-1.0.tar.gz"
    #   sha256 "2a2ba417eebaadcb4418ee7b12fe2998f26d6e6f7fda7983412ff66a741ab6f7"
    #
    #   depends_on "libxml2"
    #   depends_on "libffi"
    # end</pre>
    def stable(&block)
      @stable ||= SoftwareSpec.new
      return @stable unless block_given?

      @stable.instance_eval(&block)
    end

    # @!attribute [w] devel
    # Adds a {.devel} {SoftwareSpec}.
    # This can be installed by passing the `--devel` option to allow
    # installing non-stable (e.g. beta) versions of software.
    #
    # <pre>devel do
    #   url "https://example.com/archive-2.0-beta.tar.gz"
    #   sha256 "2a2ba417eebaadcb4418ee7b12fe2998f26d6e6f7fda7983412ff66a741ab6f7"
    #
    #   depends_on "cairo"
    #   depends_on "pixman"
    # end</pre>
    def devel(&block)
      @devel ||= SoftwareSpec.new
      return @devel unless block_given?

      @devel.instance_eval(&block)
    end

    # @!attribute [w] head
    # Adds a {.head} {SoftwareSpec}.
    # This can be installed by passing the `--HEAD` option to allow
    # installing software directly from a branch of a version-control repository.
    # If called as a method this provides just the {url} for the {SoftwareSpec}.
    # If a block is provided you can also add {.depends_on} and {Patch}es just to the {.head} {SoftwareSpec}.
    # The download strategies (e.g. `:using =>`) are the same as for {url}.
    # `master` is the default branch and doesn't need stating with a `:branch` parameter.
    # <pre>head "https://we.prefer.https.over.git.example.com/.git"</pre>
    # <pre>head "https://example.com/.git", :branch => "name_of_branch", :revision => "abc123"</pre>
    # or (if autodetect fails):
    # <pre>head "https://hg.is.awesome.but.git.has.won.example.com/", :using => :hg</pre>
    def head(val = nil, specs = {}, &block)
      @head ||= HeadSoftwareSpec.new
      if block_given?
        @head.instance_eval(&block)
      elsif val
        @head.url(val, specs)
      else
        @head
      end
    end

    # Additional downloads can be defined as resources and accessed in the
    # install method. Resources can also be defined inside a {.stable}, {.devel} or
    # {.head} block. This mechanism replaces ad-hoc "subformula" classes.
    # <pre>resource "additional_files" do
    #   url "https://example.com/additional-stuff.tar.gz"
    #   sha256 "c6bc3f48ce8e797854c4b865f6a8ff969867bbcaebd648ae6fd825683e59fef2"
    # end</pre>
    def resource(name, klass = Resource, &block)
      specs.each do |spec|
        spec.resource(name, klass, &block) unless spec.resource_defined?(name)
      end
    end

    def go_resource(name, &block)
      specs.each { |spec| spec.go_resource(name, &block) }
    end

    # The dependencies for this formula. Use strings for the names of other
    # formulae. Homebrew provides some :special dependencies for stuff that
    # requires certain extra handling (often changing some ENV vars or
    # deciding if to use the system provided version or not.)
    # <pre># `:build` means this dep is only needed during build.
    # depends_on "cmake" => :build</pre>
    # <pre>depends_on "homebrew/dupes/tcl-tk" => :optional</pre>
    # <pre># `:recommended` dependencies are built by default.
    # # But a `--without-...` option is generated to opt-out.
    # depends_on "readline" => :recommended</pre>
    # <pre># `:optional` dependencies are NOT built by default.
    # # But a `--with-...` options is generated.
    # depends_on "glib" => :optional</pre>
    # <pre># If you need to specify that another formula has to be built with/out
    # # certain options (note, no `--` needed before the option):
    # depends_on "zeromq" => "with-pgm"
    # depends_on "qt" => ["with-qtdbus", "developer"] # Multiple options.</pre>
    # <pre># Optional and enforce that boost is built with `--with-c++11`.
    # depends_on "boost" => [:optional, "with-c++11"]</pre>
    # <pre># If a dependency is only needed in certain cases:
    # depends_on "sqlite" if MacOS.version == :leopard
    # depends_on :xcode # If the formula really needs full Xcode.
    # depends_on :macos => :lion # Needs at least OS X Lion (10.7).
    # depends_on :arch => :intel # If this formula only builds on Intel architecture.
    # depends_on :arch => :x86_64 # If this formula only builds on Intel x86 64-bit.
    # depends_on :arch => :ppc # Only builds on PowerPC?
    # depends_on :ld64 # Sometimes ld fails on `MacOS.version < :leopard`. Then use this.
    # depends_on :x11 => :optional # X11/XQuartz components.
    # depends_on :osxfuse # Permits the use of the upstream signed binary or our source package.
    # depends_on :tuntap # Does the same thing as above. This is vital for Yosemite and above.</pre>
    # <pre># It is possible to only depend on something if
    # # `build.with?` or `build.without? "another_formula"`:
    # depends_on "postgresql" if build.without? "sqlite"</pre>
    # <pre># Python 3.x if the `--with-python` is given to `brew install example`
    # depends_on "python3" => :optional</pre>
    # <pre># Python 2.7:
    # depends_on "python@2"</pre>
    # <pre># Python 2.7 but use system Python where possible
    # depends_on "python@2" if MacOS.version <= :snow_leopard</pre>
    def depends_on(dep)
      specs.each { |spec| spec.depends_on(dep) }
    end

    # @!attribute [w] option
    # Options can be used as arguments to `brew install`.
    # To switch features on/off: `"with-something"` or `"with-otherthing"`.
    # To use other software: `"with-other-software"` or `"without-foo"`
    # Note that for {.depends_on} that are `:optional` or `:recommended`, options
    # are generated automatically.
    #
    # There are also some special options:
    #
    # - `:universal`: build a universal binary/library (e.g. on newer Intel Macs
    #   this means a combined x86_64/x86 binary/library).
    # <pre>option "with-spam", "The description goes here without a dot at the end"</pre>
    # <pre>option "with-qt", "Text here overwrites the autogenerated one from 'depends_on "qt" => :optional'"</pre>
    # <pre>option :universal</pre>
    def option(name, description = "")
      specs.each { |spec| spec.option(name, description) }
    end

    # @!attribute [w] deprecated_option
    # Deprecated options are used to rename options and migrate users who used
    # them to newer ones. They are mostly used for migrating non-`with` options
    # (e.g. `enable-debug`) to `with` options (e.g. `with-debug`).
    # <pre>deprecated_option "enable-debug" => "with-debug"</pre>
    def deprecated_option(hash)
      specs.each { |spec| spec.deprecated_option(hash) }
    end

    # External patches can be declared using resource-style blocks.
    # <pre>patch do
    #   url "https://example.com/example_patch.diff"
    #   sha256 "c6bc3f48ce8e797854c4b865f6a8ff969867bbcaebd648ae6fd825683e59fef2"
    # end</pre>
    #
    # A strip level of `-p1` is assumed. It can be overridden using a symbol
    # argument:
    # <pre>patch :p0 do
    #   url "https://example.com/example_patch.diff"
    #   sha256 "c6bc3f48ce8e797854c4b865f6a8ff969867bbcaebd648ae6fd825683e59fef2"
    # end</pre>
    #
    # Patches can be declared in stable, devel, and head blocks. This form is
    # preferred over using conditionals.
    # <pre>stable do
    #   patch do
    #     url "https://example.com/example_patch.diff"
    #     sha256 "c6bc3f48ce8e797854c4b865f6a8ff969867bbcaebd648ae6fd825683e59fef2"
    #   end
    # end</pre>
    #
    # Embedded (`__END__`) patches are declared like so:
    # <pre>patch :DATA
    # patch :p0, :DATA</pre>
    #
    # Patches can also be embedded by passing a string. This makes it possible
    # to provide multiple embedded patches while making only some of them
    # conditional.
    # <pre>patch :p0, "..."</pre>
    def patch(strip = :p1, src = nil, &block)
      specs.each { |spec| spec.patch(strip, src, &block) }
    end

    # Defines launchd plist handling.
    #
    # Does your plist need to be loaded at startup?
    # <pre>plist_options :startup => true</pre>
    #
    # Or only when necessary or desired by the user?
    # <pre>plist_options :manual => "foo"</pre>
    #
    # Or perhaps you'd like to give the user a choice? Ooh fancy.
    # <pre>plist_options :startup => true, :manual => "foo start"</pre>
    def plist_options(options)
      @plist_startup = options[:startup]
      @plist_manual = options[:manual]
    end

    # @private
    def conflicts
      @conflicts ||= []
    end

    # If this formula conflicts with another one.
    # <pre>conflicts_with "imagemagick", :because => "because both install 'convert' binaries"</pre>
    def conflicts_with(*names)
      opts = names.last.is_a?(Hash) ? names.pop : {}
      names.each { |name| conflicts << FormulaConflict.new(name, opts[:because]) }
    end

    def skip_clean(*paths)
      paths.flatten!
      # Specifying :all is deprecated and will become an error
      skip_clean_paths.merge(paths)
    end

    # @private
    def skip_clean_paths
      @skip_clean_paths ||= Set.new
    end

    # Software that will not be symlinked into the `brew --prefix` will only
    # live in its Cellar. Other formulae can depend on it and then brew will
    # add the necessary includes and libs (etc.) during the brewing of that
    # other formula. But generally, keg-only formulae are not in your PATH
    # and not seen by compilers if you build your own software outside of
    # Homebrew. This way, we don't shadow software provided by macOS.
    # <pre>keg_only :provided_by_macos</pre>
    # <pre>keg_only "because I want it so"</pre>
    def keg_only(reason, explanation = "")
      @keg_only_reason = KegOnlyReason.new(reason, explanation)
    end

    # Pass `:skip` to this method to disable post-install stdlib checking
    def cxxstdlib_check(check_type)
      define_method(:skip_cxxstdlib_check?) { true } if check_type == :skip
    end

    # Marks the {Formula} as failing with a particular compiler so it will fall back to others.
    # For Apple compilers, this should be in the format:
    # <pre>fails_with :clang do
    #   build 600
    #   cause "multiple configure and compile errors"
    # end</pre>
    #
    # The block may be omitted, and if present the build may be omitted;
    # if so, then the compiler will be blacklisted for *all* versions.
    #
    # `major_version` should be the major release number only, for instance
    # '4.8' for the GCC 4.8 series (4.8.0, 4.8.1, etc.).
    # If `version` or the block is omitted, then the compiler will be
    # blacklisted for all compilers in that series.
    #
    # For example, if a bug is only triggered on GCC 4.8.1 but is not
    # encountered on 4.8.2:
    #
    # <pre>fails_with :gcc => '4.8' do
    #   version '4.8.1'
    # end</pre>
    def fails_with(compiler, &block)
      specs.each { |spec| spec.fails_with(compiler, &block) }
    end

    def needs(*standards)
      specs.each { |spec| spec.needs(*standards) }
    end

    # A test is required for new formulae and makes us happy.
    # @return [Boolean]
    #
    # The block will create, run in and delete a temporary directory.
    #
    # We are fine if the executable does not error out, so we know linking
    # and building the software was OK.
    # <pre>system bin/"foobar", "--version"</pre>
    #
    # <pre>(testpath/"test.file").write <<~EOS
    #   writing some test file, if you need to
    # EOS
    # assert_equal "OK", shell_output("test_command test.file").strip</pre>
    #
    # Need complete control over stdin, stdout?
    # <pre>require "open3"
    # Open3.popen3("#{bin}/example", "argument") do |stdin, stdout, _|
    #   stdin.write("some text")
    #   stdin.close
    #   assert_equal "result", stdout.read
    # end</pre>
    #
    # The test will fail if it returns false, or if an exception is raised.
    # Failed assertions and failed `system` commands will raise exceptions.
    def test(&block)
      define_method(:test, &block)
    end

    # Defines whether the {Formula}'s bottle can be used on the given Homebrew
    # installation.
    #
    # For example, if the bottle requires the Xcode CLT to be installed a
    # {Formula} would declare:
    # <pre>pour_bottle? do
    #   reason "The bottle needs the Xcode CLT to be installed."
    #   satisfy { MacOS::CLT.installed? }
    # end</pre>
    #
    # If `satisfy` returns `false` then a bottle will not be used and instead
    # the {Formula} will be built from source and `reason` will be printed.
    def pour_bottle?(&block)
      @pour_bottle_check = PourBottleCheck.new(self)
      @pour_bottle_check.instance_eval(&block)
    end

    # @private
    def link_overwrite(*paths)
      paths.flatten!
      link_overwrite_paths.merge(paths)
    end

    # @private
    def link_overwrite_paths
      @link_overwrite_paths ||= Set.new
    end
  end
end
