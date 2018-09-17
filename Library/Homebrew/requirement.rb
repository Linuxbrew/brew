require "dependable"
require "dependency"
require "dependencies"
require "build_environment"

# A base class for non-formula requirements needed by formulae.
# A "fatal" requirement is one that will fail the build if it is not present.
# By default, Requirements are non-fatal.
class Requirement
  include Dependable

  attr_reader :tags, :name, :cask, :download

  def initialize(tags = [])
    @cask ||= self.class.cask
    @download ||= self.class.download
    tags.each do |tag|
      next unless tag.is_a? Hash

      @cask ||= tag[:cask]
      @download ||= tag[:download]
    end
    @tags = tags
    @tags << :build if self.class.build
    @name ||= infer_name
  end

  def option_names
    [name]
  end

  # The message to show when the requirement is not met.
  def message
    _, _, class_name = self.class.to_s.rpartition "::"
    s = "#{class_name} unsatisfied!\n"
    if cask
      s += <<~EOS
        You can install with Homebrew Cask:
         brew cask install #{cask}
      EOS
    end

    if download
      s += <<~EOS
        You can download from:
         #{download}
      EOS
    end
    s
  end

  # Overriding #satisfied? is unsupported.
  # Pass a block or boolean to the satisfy DSL method instead.
  def satisfied?
    satisfy = self.class.satisfy
    return true unless satisfy

    @satisfied_result = satisfy.yielder { |p| instance_eval(&p) }
    return false unless @satisfied_result

    true
  end

  # Overriding #fatal? is unsupported.
  # Pass a boolean to the fatal DSL method instead.
  def fatal?
    self.class.fatal || false
  end

  def satisfied_result_parent
    return unless @satisfied_result.is_a?(Pathname)

    parent = @satisfied_result.resolved_path.parent
    if parent.to_s =~ %r{^#{Regexp.escape(HOMEBREW_CELLAR)}/([\w+-.@]+)/[^/]+/(s?bin)/?$}
      parent = HOMEBREW_PREFIX/"opt/#{Regexp.last_match(1)}/#{Regexp.last_match(2)}"
    end
    parent
  end

  # Overriding #modify_build_environment is unsupported.
  # Pass a block to the env DSL method instead.
  def modify_build_environment
    satisfied?
    instance_eval(&env_proc) if env_proc

    # XXX If the satisfy block returns a Pathname, then make sure that it
    # remains available on the PATH. This makes requirements like
    #   satisfy { which("executable") }
    # work, even under superenv where "executable" wouldn't normally be on the
    # PATH.
    parent = satisfied_result_parent
    return unless parent
    return if ["#{HOMEBREW_PREFIX}/bin", "#{HOMEBREW_PREFIX}/bin"].include?(parent.to_s)
    return if PATH.new(ENV["PATH"]).include?(parent.to_s)

    ENV.prepend_path("PATH", parent)
  end

  def env
    self.class.env
  end

  def env_proc
    self.class.env_proc
  end

  def ==(other)
    instance_of?(other.class) && name == other.name && tags == other.tags
  end
  alias eql? ==

  def hash
    name.hash ^ tags.hash
  end

  def inspect
    "#<#{self.class.name}: #{name.inspect} #{tags.inspect}>"
  end

  def display_s
    name
  end

  def mktemp
    Mktemp.new(name).run do |staging|
      yield staging
    end
  end

  private

  def infer_name
    klass = self.class.name || self.class.to_s
    klass.sub!(/(Dependency|Requirement)$/, "")
    klass.sub!(/^(\w+::)*/, "")
    klass.downcase
  end

  def which(cmd)
    super(cmd, PATH.new(ORIGINAL_PATHS))
  end

  def which_all(cmd)
    super(cmd, PATH.new(ORIGINAL_PATHS))
  end

  class << self
    include BuildEnvironment::DSL

    attr_reader :env_proc, :build
    attr_rw :fatal, :cask, :download

    def default_formula(_val = nil)
      odisabled "Requirement.default_formula"
    end

    def satisfy(options = nil, &block)
      return @satisfied if options.nil? && !block_given?

      options = {} if options.nil?
      @satisfied = Requirement::Satisfier.new(options, &block)
    end

    def env(*settings, &block)
      if block_given?
        @env_proc = block
      else
        super
      end
    end
  end

  class Satisfier
    def initialize(options, &block)
      case options
      when Hash
        @options = { build_env: true }
        @options.merge!(options)
      else
        @satisfied = options
      end
      @proc = block
    end

    def yielder
      if instance_variable_defined?(:@satisfied)
        @satisfied
      elsif @options[:build_env]
        require "extend/ENV"
        ENV.with_build_environment { yield @proc }
      else
        yield @proc
      end
    end
  end

  class << self
    # Expand the requirements of dependent recursively, optionally yielding
    # [dependent, req] pairs to allow callers to apply arbitrary filters to
    # the list.
    # The default filter, which is applied when a block is not given, omits
    # optionals and recommendeds based on what the dependent has asked for.
    def expand(dependent, &block)
      reqs = Requirements.new

      formulae = dependent.recursive_dependencies.map(&:to_formula)
      formulae.unshift(dependent)

      formulae.each do |f|
        f.requirements.each do |req|
          next if prune?(f, req, &block)

          reqs << req
        end
      end

      reqs
    end

    def prune?(dependent, req, &_block)
      catch(:prune) do
        if block_given?
          yield dependent, req
        elsif req.optional? || req.recommended?
          prune unless dependent.build.with?(req)
        end
      end
    end

    # Used to prune requirements when calling expand with a block.
    def prune
      throw(:prune, true)
    end
  end
end
