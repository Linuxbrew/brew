class RubyRequirement < Requirement
  fatal true
  default_formula "ruby"

  def initialize(tags)
    @version = tags.shift if /(\d\.)+\d/ =~ tags.first
    raise "RubyRequirement requires a version!" unless @version
    super
  end

  satisfy build_env: false { suitable_ruby }

  env do
    ENV.prepend_path "PATH", suitable_ruby
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

  def suitable_ruby
    rubies.detect { |ruby| suitable?(ruby) }
  end

  def rubies
    rubies = which_all("ruby")
    if ruby_formula.installed?
      rubies.unshift Pathname.new(ruby_formula.bin/"ruby")
    end
    rubies.uniq
  end

  def suitable?(ruby)
    version = Utils.popen_read(ruby, "-e", "print RUBY_VERSION").strip
    version =~ /^\d+\.\d+/ && Version.create(version) >= min_version
  end

  def min_version
    @min_version ||= Version.create(@version)
  end

  def ruby_formula
    @ruby_formula ||= Formula["ruby"]
  rescue FormulaUnavailableError
    nil
  end

end
