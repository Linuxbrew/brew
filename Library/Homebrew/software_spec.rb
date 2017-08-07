require "resource"
require "checksum"
require "version"
require "options"
require "build_options"
require "dependency_collector"
require "utils/bottles"
require "patch"
require "compilers"
require "os/mac/version"

class SoftwareSpec
  extend Forwardable

  PREDEFINED_OPTIONS = {
    universal: Option.new("universal", "Build a universal binary"),
    cxx11:     Option.new("c++11",     "Build using C++11 mode"),
  }.freeze

  attr_reader :name, :full_name, :owner
  attr_reader :build, :resources, :patches, :options
  attr_reader :deprecated_flags, :deprecated_options
  attr_reader :dependency_collector
  attr_reader :bottle_specification
  attr_reader :compiler_failures

  def_delegators :@resource, :stage, :fetch, :verify_download_integrity, :source_modified_time
  def_delegators :@resource, :cached_download, :clear_cache
  def_delegators :@resource, :checksum, :mirrors, :specs, :using
  def_delegators :@resource, :version, :mirror, *Checksum::TYPES
  def_delegators :@resource, :downloader

  def initialize
    @resource = Resource.new
    @resources = {}
    @dependency_collector = DependencyCollector.new
    @bottle_specification = BottleSpecification.new
    @patches = []
    @options = Options.new
    @flags = ARGV.flags_only
    @deprecated_flags = []
    @deprecated_options = []
    @build = BuildOptions.new(Options.create(@flags), options)
    @compiler_failures = []
  end

  def owner=(owner)
    @name = owner.name
    @full_name = owner.full_name
    @bottle_specification.tap = owner.tap
    @owner = owner
    @resource.owner = self
    resources.each_value do |r|
      r.owner = self
      r.version ||= begin
        if version.nil?
          raise "#{full_name}: version missing for \"#{r.name}\" resource!"
        end

        if version.head?
          Version.create("HEAD")
        else
          version.dup
        end
      end
    end
    patches.each { |p| p.owner = self }
  end

  def url(val = nil, specs = {})
    return @resource.url if val.nil?
    @resource.url(val, specs)
    dependency_collector.add(@resource)
  end

  def bottle_unneeded?
    return false unless @bottle_disable_reason
    @bottle_disable_reason.unneeded?
  end

  def bottle_disabled?
    @bottle_disable_reason ? true : false
  end

  attr_reader :bottle_disable_reason

  def bottle_defined?
    !bottle_specification.collector.keys.empty?
  end

  def bottled?
    bottle_specification.tag?(Utils::Bottles.tag) && \
      (bottle_specification.compatible_cellar? || ARGV.force_bottle?)
  end

  def bottle(disable_type = nil, disable_reason = nil, &block)
    if disable_type
      @bottle_disable_reason = BottleDisableReason.new(disable_type, disable_reason)
    else
      bottle_specification.instance_eval(&block)
    end
  end

  def resource_defined?(name)
    resources.key?(name)
  end

  def resource(name, klass = Resource, &block)
    if block_given?
      raise DuplicateResourceError, name if resource_defined?(name)
      res = klass.new(name, &block)
      resources[name] = res
      dependency_collector.add(res)
    else
      resources.fetch(name) { raise ResourceMissingError.new(owner, name) }
    end
  end

  def go_resource(name, &block)
    resource name, Resource::Go, &block
  end

  def option_defined?(name)
    options.include?(name)
  end

  def option(name, description = "")
    opt = PREDEFINED_OPTIONS.fetch(name) do
      if name.is_a?(Symbol)
        odeprecated "passing arbitrary symbols (i.e. #{name.inspect}) to `option`"
        name = name.to_s
      end
      unless name.is_a?(String)
        raise ArgumentError, "option name must be string or symbol; got a #{name.class}: #{name}"
      end
      raise ArgumentError, "option name is required" if name.empty?
      raise ArgumentError, "option name must be longer than one character: #{name}" unless name.length > 1
      raise ArgumentError, "option name must not start with dashes: #{name}" if name.start_with?("-")
      Option.new(name, description)
    end
    options << opt
  end

  def deprecated_option(hash)
    raise ArgumentError, "deprecated_option hash must not be empty" if hash.empty?
    hash.each do |old_options, new_options|
      Array(old_options).each do |old_option|
        Array(new_options).each do |new_option|
          deprecated_option = DeprecatedOption.new(old_option, new_option)
          deprecated_options << deprecated_option

          old_flag = deprecated_option.old_flag
          new_flag = deprecated_option.current_flag
          next unless @flags.include? old_flag
          @flags -= [old_flag]
          @flags |= [new_flag]
          @deprecated_flags << deprecated_option
        end
      end
    end
    @build = BuildOptions.new(Options.create(@flags), options)
  end

  def depends_on(spec)
    dep = dependency_collector.add(spec)
    add_dep_option(dep) if dep
  end

  def deps
    dependency_collector.deps
  end

  def recursive_dependencies
    deps_f = []
    recursive_dependencies = deps.map do |dep|
      begin
        deps_f << dep.to_formula
        dep
      rescue TapFormulaUnavailableError
        # Don't complain about missing cross-tap dependencies
        next
      end
    end.compact.uniq
    deps_f.compact.each do |f|
      f.recursive_dependencies.each do |dep|
        recursive_dependencies << dep unless recursive_dependencies.include?(dep)
      end
    end
    recursive_dependencies
  end

  def requirements
    dependency_collector.requirements
  end

  def recursive_requirements
    Requirement.expand(self)
  end

  def patch(strip = :p1, src = nil, &block)
    p = Patch.create(strip, src, &block)
    dependency_collector.add(p.resource) if p.is_a? ExternalPatch
    patches << p
  end

  def fails_with(compiler, &block)
    odeprecated "fails_with :llvm" if compiler == :llvm
    compiler_failures << CompilerFailure.create(compiler, &block)
  end

  def needs(*standards)
    standards.each do |standard|
      compiler_failures.concat CompilerFailure.for_standard(standard)
    end
  end

  def add_legacy_patches(list)
    list = Patch.normalize_legacy_patches(list)
    list.each { |p| p.owner = self }
    patches.concat(list)
  end

  def add_dep_option(dep)
    dep.option_names.each do |name|
      if dep.optional? && !option_defined?("with-#{name}")
        options << Option.new("with-#{name}", "Build with #{name} support")
      elsif dep.recommended? && !option_defined?("without-#{name}")
        options << Option.new("without-#{name}", "Build without #{name} support")
      end
    end
  end
end

class HeadSoftwareSpec < SoftwareSpec
  def initialize
    super
    @resource.version = Version.create("HEAD")
  end

  def verify_download_integrity(_fn)
    nil
  end
end

class Bottle
  class Filename
    attr_reader :name, :version, :tag, :rebuild

    def self.create(formula, tag, rebuild)
      new(formula.name, formula.pkg_version, tag, rebuild)
    end

    def initialize(name, version, tag, rebuild)
      @name = name
      @version = version
      @tag = tag.to_s.gsub(/_or_later$/, "")
      @rebuild = rebuild
    end

    def to_s
      prefix + suffix
    end
    alias to_str to_s

    def prefix
      "#{name}-#{version}.#{tag}"
    end

    def suffix
      s = (rebuild > 0) ? ".#{rebuild}" : ""
      ".bottle#{s}.tar.gz"
    end
  end

  extend Forwardable

  attr_reader :name, :resource, :prefix, :cellar, :rebuild

  def_delegators :resource, :url, :fetch, :verify_download_integrity
  def_delegators :resource, :cached_download, :clear_cache

  def initialize(formula, spec)
    @name = formula.name
    @resource = Resource.new
    @resource.owner = formula
    @spec = spec

    checksum, tag = spec.checksum_for(Utils::Bottles.tag)

    filename = Filename.create(formula, tag, spec.rebuild)
    @resource.url(build_url(spec.root_url, filename))
    @resource.download_strategy = CurlBottleDownloadStrategy
    @resource.version = formula.pkg_version
    @resource.checksum = checksum
    @prefix = spec.prefix
    @cellar = spec.cellar
    @rebuild = spec.rebuild
  end

  def compatible_cellar?
    @spec.compatible_cellar?
  end

  # Does the bottle need to be relocated?
  def skip_relocation?
    @spec.skip_relocation?
  end

  def stage
    resource.downloader.stage
  end

  private

  def build_url(root_url, filename)
    "#{root_url}/#{filename}"
  end
end

class BottleSpecification
  DEFAULT_PREFIX = "/usr/local".freeze
  DEFAULT_CELLAR = "/usr/local/Cellar".freeze
  DEFAULT_DOMAIN = (ENV["HOMEBREW_BOTTLE_DOMAIN"] || "https://homebrew.bintray.com").freeze

  attr_rw :prefix, :cellar, :rebuild
  attr_accessor :tap
  attr_reader :checksum, :collector

  def initialize
    @rebuild = 0
    @prefix = DEFAULT_PREFIX
    @cellar = DEFAULT_CELLAR
    @collector = Utils::Bottles::Collector.new
  end

  def root_url(var = nil)
    if var.nil?
      @root_url ||= "#{DEFAULT_DOMAIN}/#{Utils::Bottles::Bintray.repository(tap)}"
    else
      @root_url = var
    end
  end

  def compatible_cellar?
    cellar == :any || cellar == :any_skip_relocation || cellar == HOMEBREW_CELLAR.to_s
  end

  # Does the Bottle this BottleSpecification belongs to need to be relocated?
  def skip_relocation?
    cellar == :any_skip_relocation
  end

  def tag?(tag)
    checksum_for(tag) ? true : false
  end

  # Checksum methods in the DSL's bottle block optionally take
  # a Hash, which indicates the platform the checksum applies on.
  Checksum::TYPES.each do |cksum|
    define_method(cksum) do |val|
      digest, tag = val.shift
      collector[tag] = Checksum.new(cksum, digest)
    end
  end

  def checksum_for(tag)
    collector.fetch_checksum_for(tag)
  end

  def checksums
    tags = collector.keys.sort_by do |tag|
      # Sort non-MacOS tags below MacOS tags.
      begin
        OS::Mac::Version.from_symbol tag
      rescue ArgumentError
        "0.#{tag}"
      end
    end
    checksums = {}
    tags.reverse_each do |tag|
      checksum = collector[tag]
      checksums[checksum.hash_type] ||= []
      checksums[checksum.hash_type] << { checksum => tag }
    end
    checksums
  end
end

class PourBottleCheck
  def initialize(formula)
    @formula = formula
  end

  def reason(reason)
    @formula.pour_bottle_check_unsatisfied_reason = reason
  end

  def satisfy(&block)
    @formula.send(:define_method, :pour_bottle?, &block)
  end
end
