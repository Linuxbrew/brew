require "language/java"

class JavaRequirement < Requirement
  fatal true
  default_formula "jdk" if OS.linux?
  cask "java"
  download "http://www.oracle.com/technetwork/java/javase/downloads/index.html"

  satisfy build_env: false do
    unless File.executable? "/usr/libexec/java_home"
      jdk = Formula["jdk"]
      @java_home = jdk.opt_prefix if jdk
      next quiet_system "java", "-version"
    end

    args = %w[--failfast]
    args << "--version" << @version.to_s if @version
    @java_home = Utils.popen_read("/usr/libexec/java_home", *args).chomp
    $?.success?
  end

  env do
    next unless @java_home
    java_home = Pathname.new(@java_home)
    ENV["JAVA_HOME"] = java_home
    ENV.prepend_path "PATH", java_home/"bin"
    if (java_home/"include").exist? # Oracle JVM
      ENV.append_to_cflags "-I#{java_home}/include"
      ENV.append_to_cflags "-I#{java_home}/include/#{OS::NAME}"
    else # Apple JVM
      ENV.append_to_cflags "-I/System/Library/Frameworks/JavaVM.framework/Versions/Current/Headers/"
    end
  end

  def initialize(tags)
    @version = tags.shift if /(\d\.)+\d/ =~ tags.first
    super
  end

  def message
    version_string = " #{@version}" if @version

    s = "Java#{version_string} is required to install this formula."
    s += super
    s
  end

  def inspect
    "#<#{self.class.name}: #{name.inspect} #{tags.inspect} version=#{@version.inspect}>"
  end

  def display_s
    if @version
      if @version[-1] == "+"
        op = ">="
        version = @version[0, @version.length-1]
      else
        op = "="
        version = @version
      end
      "#{name} #{op} #{version}"
    else
      name
    end
  end
end
