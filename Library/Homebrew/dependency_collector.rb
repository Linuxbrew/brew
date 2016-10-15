require "dependency"
require "dependencies"
require "ld64_dependency"
require "requirement"
require "requirements"
require "set"

## A dependency is a formula that another formula needs to install.
## A requirement is something other than a formula that another formula
## needs to be present. This includes external language modules,
## command-line tools in the path, or any arbitrary predicate.
##
## The `depends_on` method in the formula DSL is used to declare
## dependencies and requirements.

# This class is used by `depends_on` in the formula DSL to turn dependency
# specifications into the proper kinds of dependencies and requirements.
class DependencyCollector
  # Define the languages that we can handle as external dependencies.
  LANGUAGE_MODULES = Set[
    :lua, :lua51, :perl, :python, :python3, :ruby
  ].freeze

  CACHE = {}

  def self.clear_cache
    CACHE.clear
  end

  attr_reader :deps, :requirements

  def initialize
    @deps = Dependencies.new
    @requirements = Requirements.new
  end

  def add(spec)
    case dep = fetch(spec)
    when Dependency
      @deps << dep
    when Requirement
      @requirements << dep
    end
    dep
  end

  def fetch(spec)
    CACHE.fetch(cache_key(spec)) { |key| CACHE[key] = build(spec) }
  end

  def cache_key(spec)
    if spec.is_a?(Resource) && spec.download_strategy == CurlDownloadStrategy
      File.extname(spec.url)
    else
      spec
    end
  end

  def build(spec)
    spec, tags = spec.is_a?(Hash) ? spec.first : spec
    parse_spec(spec, Array(tags))
  end

  def self.tar_needs_xz_dependency?
    !new.xz_dep([]).nil?
  end

  private

  def parse_spec(spec, tags)
    case spec
    when String
      parse_string_spec(spec, tags)
    when Resource
      resource_dep(spec, tags)
    when Symbol
      parse_symbol_spec(spec, tags)
    when Requirement, Dependency
      spec
    when Class
      parse_class_spec(spec, tags)
    else
      raise TypeError, "Unsupported type #{spec.class.name} for #{spec.inspect}"
    end
  end

  def parse_string_spec(spec, tags)
    if spec =~ HOMEBREW_TAP_FORMULA_REGEX
      TapDependency.new(spec, tags)
    elsif tags.empty?
      Dependency.new(spec, tags)
    elsif (tag = tags.first) && LANGUAGE_MODULES.include?(tag)
      LanguageModuleRequirement.new(tag, spec, tags[1])
    else
      Dependency.new(spec, tags)
    end
  end

  def parse_symbol_spec(spec, tags)
    case spec
    when :x11        then X11Requirement.new(spec.to_s, tags)
    when :xcode      then XcodeRequirement.new(tags)
    when :macos      then MinimumMacOSRequirement.new(tags)
    when :mysql      then MysqlRequirement.new(tags)
    when :postgresql then PostgresqlRequirement.new(tags)
    when :gpg        then GPG2Requirement.new(tags)
    when :fortran    then FortranRequirement.new(tags)
    when :mpi        then MPIRequirement.new(*tags)
    when :tex        then TeXRequirement.new(tags)
    when :arch       then ArchRequirement.new(tags)
    when :hg         then MercurialRequirement.new(tags)
    when :python     then PythonRequirement.new(tags)
    when :python3    then Python3Requirement.new(tags)
    when :java       then JavaRequirement.new(tags)
    when :rbenv      then RbenvRequirement.new(tags)
    when :ruby       then RubyRequirement.new(tags)
    when :osxfuse    then OsxfuseRequirement.new(tags)
    when :perl       then PerlRequirement.new(tags)
    when :tuntap     then TuntapRequirement.new(tags)
    when :ant        then ant_dep(tags)
    when :emacs      then EmacsRequirement.new(tags)
    # Tiger's ld is too old to properly link some software
    when :ld64       then LD64Dependency.new if MacOS.version < :leopard
    # Tiger doesn't ship expat in /usr/lib
    when :expat      then Dependency.new("expat", tag) if MacOS.version < :leopard
    when :python2
      PythonRequirement.new(tags)
    else
      raise ArgumentError, "Unsupported special dependency #{spec.inspect}"
    end
  end

  def parse_class_spec(spec, tags)
    unless spec < Requirement
      raise TypeError, "#{spec.inspect} is not a Requirement subclass"
    end

    spec.new(tags)
  end

  def ant_dep(tags)
    Dependency.new("ant", tags)
  end

  def xz_dep(tags)
    Dependency.new("xz", tags)
  end

  def resource_dep(spec, tags)
    tags << :build
    strategy = spec.download_strategy

    if strategy <= CurlDownloadStrategy
      parse_url_spec(spec.url, tags)
    elsif strategy <= GitDownloadStrategy
      GitRequirement.new(tags)
    elsif strategy <= MercurialDownloadStrategy
      MercurialRequirement.new(tags)
    elsif strategy <= FossilDownloadStrategy
      Dependency.new("fossil", tags)
    elsif strategy <= BazaarDownloadStrategy
      Dependency.new("bazaar", tags)
    elsif strategy <= CVSDownloadStrategy
      Dependency.new("cvs", tags) if MacOS.version >= :mavericks || !MacOS::Xcode.provides_cvs?
    elsif strategy < AbstractDownloadStrategy
      # allow unknown strategies to pass through
    else
      raise TypeError,
        "#{strategy.inspect} is not an AbstractDownloadStrategy subclass"
    end
  end

  def parse_url_spec(url, tags)
    case File.extname(url)
    when ".xz"          then xz_dep(tags)
    when ".lha", ".lzh" then Dependency.new("lha", tags)
    when ".lz"          then Dependency.new("lzip", tags)
    when ".rar"         then Dependency.new("unrar", tags)
    when ".7z"          then Dependency.new("p7zip", tags)
    end
  end
end

require "extend/os/dependency_collector"
