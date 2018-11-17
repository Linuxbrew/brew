require "dependency"
require "dependencies"
require "requirement"
require "requirements"
require "extend/cachable"

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
  extend Cachable

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
    self.class.cache.fetch(cache_key(spec)) { |key| self.class.cache[key] = build(spec) }
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

  def git_dep_if_needed(tags)
    return if Utils.git_available?

    Dependency.new("git", tags)
  end

  def subversion_dep_if_needed(tags)
    return if Utils.svn_available?

    Dependency.new("subversion", tags)
  end

  def cvs_dep_if_needed(tags)
    Dependency.new("cvs", tags) unless which("cvs")
  end

  def xz_dep_if_needed(tags)
    Dependency.new("xz", tags) unless which("xz")
  end

  def unzip_dep_if_needed(tags)
    Dependency.new("unzip", tags) unless which("unzip")
  end

  def bzip2_dep_if_needed(tags)
    Dependency.new("bzip2", tags) unless which("bzip2")
  end

  def java_dep_if_needed(tags)
    JavaRequirement.new(tags)
  end

  def ld64_dep_if_needed(*); end

  def self.tar_needs_xz_dependency?
    !new.xz_dep_if_needed([]).nil?
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
    else
      Dependency.new(spec, tags)
    end
  end

  def parse_symbol_spec(spec, tags)
    case spec
    when :arch          then ArchRequirement.new(tags)
    when :codesign      then CodesignRequirement.new(tags)
    when :java          then java_dep_if_needed(tags)
    when :linux         then LinuxRequirement.new(tags)
    when :macos         then MacOSRequirement.new(tags)
    when :maximum_macos then MaximumMacOSRequirement.new(tags)
    when :osxfuse       then OsxfuseRequirement.new(tags)
    when :tuntap        then TuntapRequirement.new(tags)
    when :x11           then X11Requirement.new(tags)
    when :xcode         then XcodeRequirement.new(tags)
    when :ld64          then ld64_dep_if_needed(tags)
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

  def resource_dep(spec, tags)
    tags << :build
    strategy = spec.download_strategy

    if strategy <= CurlDownloadStrategy
      parse_url_spec(spec.url, tags)
    elsif strategy <= GitDownloadStrategy
      git_dep_if_needed(tags)
    elsif strategy <= SubversionDownloadStrategy
      subversion_dep_if_needed(tags)
    elsif strategy <= MercurialDownloadStrategy
      Dependency.new("mercurial", tags)
    elsif strategy <= FossilDownloadStrategy
      Dependency.new("fossil", tags)
    elsif strategy <= BazaarDownloadStrategy
      Dependency.new("bazaar", tags)
    elsif strategy <= CVSDownloadStrategy
      cvs_dep_if_needed(tags)
    elsif strategy < AbstractDownloadStrategy
      # allow unknown strategies to pass through
    else
      raise TypeError,
        "#{strategy.inspect} is not an AbstractDownloadStrategy subclass"
    end
  end

  def parse_url_spec(url, tags)
    case File.extname(url)
    when ".xz"          then xz_dep_if_needed(tags)
    when ".zip"         then unzip_dep_if_needed(tags)
    when ".bz2"         then bzip2_dep_if_needed(tags)
    when ".lha", ".lzh" then Dependency.new("lha", tags)
    when ".lz"          then Dependency.new("lzip", tags)
    when ".rar"         then Dependency.new("unrar", tags)
    when ".7z"          then Dependency.new("p7zip", tags)
    end
  end
end

require "extend/os/dependency_collector"
