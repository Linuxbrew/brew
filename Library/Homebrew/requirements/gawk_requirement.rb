class GawkRequirement < Requirement
  fatal true
  default_formula "gawk"

  def initialize(tags)
    @version = tags.shift if /(\d\.)+\d/ === tags.first
    raise "GawkRequirement requires a version!" unless @version
    super
  end

  satisfy :build_env => false do
    which_all("gawk").detect do |gawk|
      version = /\d\.\d/.match Utils.popen_read(gawk, "--version")
      next unless version
      Version.new(version.to_s) >= Version.new(@version)
    end
  end

  def message
    s = "Gawk #{@version} is required to install this formula."
    s += super
    s
  end

  def inspect
    "#<#{self.class.name}: #{name.inspect} #{tags.inspect} version=#{@version.inspect}>"
  end
end

