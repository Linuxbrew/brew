require "language/java"

class JavaRequirement < Requirement
  fatal true
  download "https://www.oracle.com/technetwork/java/javase/downloads/index.html"

  # A strict Java 8 requirement (1.8) should prompt the user to install
  # the legacy java8 cask because versions newer than Java 8 are not
  # completely backwards compatible, and contain breaking changes such as
  # strong encapsulation of JDK-internal APIs and a modified version scheme
  # (*.0 not 1.*).
  def cask
    if @version.nil? || @version.to_s.end_with?("+") ||
       @version.to_f >= JAVA_CASK_MAP.keys.max.to_f
      JAVA_CASK_MAP.fetch(JAVA_CASK_MAP.keys.max)
    else
      JAVA_CASK_MAP.fetch("1.8")
    end
  end

  satisfy build_env: false do
    setup_java
    next false unless @java

    next true
  end

  def initialize(tags = [])
    @version = tags.shift if /(\d+\.)+\d/ =~ tags.first
    super(tags)
  end

  def message
    version_string = " #{@version}" if @version

    s = "Java#{version_string} is required to install this formula.\n"
    s += super
    s
  end

  def inspect
    "#<#{self.class.name}: #{tags.inspect} version=#{@version.inspect}>"
  end

  def display_s
    if @version
      if exact_version?
        op = "="
      else
        op = ">="
      end
      "#{name} #{op} #{version_without_plus}"
    else
      name
    end
  end

  private

  JAVA_CASK_MAP = {
    "1.8"  => "homebrew/cask-versions/java8",
    "11.0" => "java",
  }.freeze

  def version_without_plus
    if exact_version?
      @version
    else
      @version[0, @version.length - 1]
    end
  end

  def exact_version?
    @version && @version.to_s.chars.last != "+"
  end

  def setup_java
    java = preferred_java
    return unless java

    @java = java
    @java_home = java.parent.parent
  end

  def possible_javas
    javas = []
    javas << Pathname.new(ENV["JAVA_HOME"])/"bin/java" if ENV["JAVA_HOME"]
    jdk = begin
      Formula["openjdk"]
    rescue FormulaUnavailableError
      nil
    end
    javas << jdk.bin/"java" if jdk&.installed?
    javas << which("java")
    javas
  end

  def preferred_java
    possible_javas.find do |java|
      next false unless java&.executable?
      next true unless @version
      next true if satisfies_version(java)
    end
  end

  def env_java_common
    return unless @java_home

    java_home = Pathname.new(@java_home)
    ENV["JAVA_HOME"] = java_home
    ENV.prepend_path "PATH", java_home/"bin"
  end

  def env_oracle_jdk
    return unless @java_home

    java_home = Pathname.new(@java_home)
    return unless (java_home/"include").exist?

    ENV.append_to_cflags "-I#{java_home}/include"
    ENV.append_to_cflags "-I#{java_home}/include/#{oracle_java_os}"
    true
  end

  def oracle_java_os
    nil
  end

  def satisfies_version(java)
    java_version_s = system_command(java, args: ["-version"], print_stderr: false).stderr[/\d+.\d/]
    return false unless java_version_s

    java_version = Version.create(java_version_s)
    needed_version = Version.create(version_without_plus)
    if exact_version?
      java_version == needed_version
    else
      java_version >= needed_version
    end
  end
end

require "extend/os/requirements/java_requirement"
