class RubyRequirement < Requirement
  fatal true
  default_formula "ruby"

  def initialize(tags)
    @version = tags.shift if /(\d\.)+\d/ =~ tags.first
    raise "RubyRequirement requires a version!" unless @version
    super
  end

  satisfy(build_env: false) { new_enough_ruby }

  env do
    ENV.prepend_path "PATH", new_enough_ruby.dirname unless new_enough_ruby.nil?
  end

  def message
    s = "Ruby >= #{@version} is required to install this formula."
    s += super
    s
  end

  def inspect
    "#<#{self.class.name}: #{name.inspect} #{tags.inspect} version=#{@version.inspect}>"
  end

  def display_s
    if @version
      "#{name} >= #{@version}"
    else
      name
    end
  end

  private

  def new_enough_ruby
    rubies.detect do |ruby|
      next unless new_enough?(ruby)
      rubyhdrdir = Pathname.new Utils.popen_read(ruby, "-rrbconfig", "-e", "print RbConfig::CONFIG['rubyhdrdir']")
      next unless (rubyhdrdir/"ruby.h").readable?
    end
  end

  def rubies
    rubies = which_all("ruby")
    ruby_formula = Formula["ruby"]
    if ruby_formula && ruby_formula.installed?
      rubies.unshift ruby_formula.bin/"ruby"
    end
    rubies.push RUBY_PATH unless rubies.include? RUBY_PATH
    rubies.uniq
  end

  def new_enough?(ruby)
    version = Utils.popen_read(ruby, "-e", "print RUBY_VERSION").strip
    version =~ /^\d+\.\d+/ && Version.create(version) >= min_version
  end

  def min_version
    @min_version ||= Version.create(@version)
  end
end
