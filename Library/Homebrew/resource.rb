require "download_strategy"
require "checksum"
require "version"

# Resource is the fundamental representation of an external resource. The
# primary formula download, along with other declared resources, are instances
# of this class.
class Resource
  include FileUtils

  attr_reader :mirrors, :specs, :using, :source_modified_time
  attr_writer :version
  attr_accessor :download_strategy, :checksum

  # Formula name must be set after the DSL, as we have no access to the
  # formula name before initialization of the formula
  attr_accessor :name, :owner

  class Download
    def initialize(resource)
      @resource = resource
    end

    def url
      @resource.url
    end

    def specs
      @resource.specs
    end

    def version
      @resource.version
    end

    def mirrors
      @resource.mirrors
    end
  end

  def initialize(name = nil, &block)
    @name = name
    @url = nil
    @version = nil
    @mirrors = []
    @specs = {}
    @checksum = nil
    @using = nil
    instance_eval(&block) if block_given?
  end

  def downloader
    download_strategy.new(download_name, Download.new(self))
  end

  # Removes /s from resource names; this allows go package names
  # to be used as resource names without confusing software that
  # interacts with download_name, e.g. github.com/foo/bar
  def escaped_name
    name.tr("/", "-")
  end

  def download_name
    name.nil? ? owner.name : "#{owner.name}--#{escaped_name}"
  end

  def cached_download
    downloader.cached_location
  end

  def clear_cache
    downloader.clear_cache
  end

  # Verifies download and unpacks it
  # The block may call `|resource,staging| staging.retain!` to retain the staging
  # directory. Subclasses that override stage should implement the tmp
  # dir using FileUtils.mktemp so that works with all subtypes.
  def stage(target = nil, &block)
    unless target || block
      raise ArgumentError, "target directory or block is required"
    end

    verify_download_integrity(fetch)
    unpack(target, &block)
  end

  # If a target is given, unpack there; else unpack to a temp folder.
  # If block is given, yield to that block with |stage|, where stage
  # is a ResourceStagingContext.
  # A target or a block must be given, but not both.
  def unpack(target = nil)
    mktemp(download_name) do |staging|
      downloader.stage
      @source_modified_time = downloader.source_modified_time
      if block_given?
        yield ResourceStageContext.new(self, staging)
      elsif target
        target = Pathname.new(target) unless target.is_a? Pathname
        target.install Pathname.pwd.children
      end
    end
  end

  Partial = Struct.new(:resource, :files)

  def files(*files)
    Partial.new(self, files)
  end

  def fetch
    HOMEBREW_CACHE.mkpath

    begin
      downloader.fetch
    rescue ErrorDuringExecution, CurlDownloadStrategyError => e
      raise DownloadError.new(self, e)
    end

    cached_download
  end

  def verify_download_integrity(fn)
    if fn.file?
      ohai "Verifying #{fn.basename} checksum" if ARGV.verbose?
      fn.verify_checksum(checksum)
    end
  rescue ChecksumMissingError
    opoo "Cannot verify integrity of #{fn.basename}"
    puts "A checksum was not provided for this resource"
    puts "For your reference the SHA256 is: #{fn.sha256}"
  end

  Checksum::TYPES.each do |type|
    define_method(type) { |val| @checksum = Checksum.new(type, val) }
  end

  def url(val = nil, specs = {})
    return @url if val.nil?
    @url = val
    @specs.merge!(specs)
    @using = @specs.delete(:using)
    @download_strategy = DownloadStrategyDetector.detect(url, using)
  end

  def version(val = nil)
    @version ||= begin
      version = detect_version(val)
      version.null? ? nil : version
    end
  end

  def mirror(val)
    mirrors << val
  end

  private

  def detect_version(val)
    return Version::NULL if val.nil? && url.nil?

    case val
    when nil     then Version.detect(url, specs)
    when String  then Version.create(val)
    when Version then val
    else
      raise TypeError, "version '#{val.inspect}' should be a string"
    end
  end

  class Go < Resource
    def stage(target)
      super(target/name)
    end
  end

  class Patch < Resource
    attr_reader :patch_files

    def initialize(&block)
      @patch_files = []
      super "patch", &block
    end

    def apply(*paths)
      paths.flatten!
      @patch_files.concat(paths)
      @patch_files.uniq!
    end
  end
end

# The context in which a Resource.stage() occurs. Supports access to both
# the Resource and associated Mktemp in a single block argument. The interface
# is back-compatible with Resource itself as used in that context.
class ResourceStageContext
  extend Forwardable

  # The Resource that is being staged
  attr_reader :resource
  # The Mktemp in which @resource is staged
  attr_reader :staging

  def_delegators :@resource, :version, :url, :mirrors, :specs, :using, :source_modified_time
  def_delegators :@staging, :retain!

  def initialize(resource, staging)
    @resource = resource
    @staging = staging
  end

  def to_s
    "<#{self.class}: resource=#{resource} staging=#{staging}>"
  end
end
