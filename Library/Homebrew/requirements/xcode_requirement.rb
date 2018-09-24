require "requirement"

class XcodeRequirement < Requirement
  fatal true

  satisfy(build_env: false) { xcode_installed_version }

  def initialize(tags = [])
    @version = tags.find { |tag| tags.delete(tag) if tag =~ /(\d\.)+\d/ }
    super
  end

  def xcode_installed_version
    return false unless MacOS::Xcode.installed?
    return true unless @version

    MacOS::Xcode.version >= @version
  end

  def message
    version = " #{@version}" if @version
    message = <<~EOS
      A full installation of Xcode.app#{version} is required to compile this software.
      Installing just the Command Line Tools is not sufficient.
    EOS
    if @version && Version.new(MacOS::Xcode.latest_version) < Version.new(@version)
      message + <<~EOS
        Xcode#{version} cannot be installed on macOS #{MacOS.version}.
        You must upgrade your version of macOS.
      EOS
    elsif MacOS.version >= :lion
      message + <<~EOS
        Xcode can be installed from the App Store.
      EOS
    else
      message + <<~EOS
        Xcode can be installed from #{Formatter.url("https://developer.apple.com/download/more/")}.
      EOS
    end
  end

  def inspect
    "#<#{self.class.name}: #{name.inspect} #{tags.inspect} version=#{@version.inspect}>"
  end
end
