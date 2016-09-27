class PerlRequirement < Requirement
  fatal true
  default_formula "perl"

  def initialize(tags)
    @version = tags.shift if /^\d+\.\d+$/ =~ tags.first
    raise "PerlRequirement requires a version!" unless @version
    super
  end

  satisfy(build_env: false) do
    which_all("perl").detect do |perl|
      perl_version = Utils.popen_read(perl, "--version")[/\(v(\d+\.\d+)(?:\.\d+)?\)/, 1]
      next unless perl_version
      Version.create(perl_version.to_s) >= Version.create(@version)
    end
  end

  def message
    s = "Perl #{@version} is required to install this formula."
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
end
