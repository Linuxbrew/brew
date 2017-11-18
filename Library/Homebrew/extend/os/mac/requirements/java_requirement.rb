class JavaRequirement < Requirement
  env do
    env_java_common
    env_oracle_jdk || env_apple
  end

  # A strict Java 8 requirement (1.8) should prompt the user to install
  # the legacy java8 cask because the current version, Java 9, is not
  # completely backwards compatible, and contains breaking changes such as
  # strong encapsulation of JDK-internal APIs and a modified version scheme
  # (9.0 not 1.9).
  def cask
    if @version.nil? || @version.to_s.end_with?("+") ||
       @version.to_f >= JAVA_CASK_MAP.keys.max.to_f
      JAVA_CASK_MAP.fetch(JAVA_CASK_MAP.keys.max)
    else
      JAVA_CASK_MAP.fetch("1.8")
    end
  end

  private

  JAVA_CASK_MAP = {
    "1.8" => "caskroom/versions/java8",
    "9.0" => "java",
  }.freeze

  def possible_javas
    javas = []
    javas << Pathname.new(ENV["JAVA_HOME"])/"bin/java" if ENV["JAVA_HOME"]
    javas << java_home_cmd
    which_java = which("java")
    # /usr/bin/java is a stub on macOS
    javas << which_java if which_java.to_s != "/usr/bin/java"
    javas
  end

  def java_home_cmd
    return nil unless File.executable?("/usr/libexec/java_home")
    args = %w[--failfast]
    args << "--version" << @version.to_s if @version
    java_home = Utils.popen_read("/usr/libexec/java_home", *args).chomp
    return nil unless $CHILD_STATUS.success?
    Pathname.new(java_home)/"bin/java"
  end

  def env_apple
    ENV.append_to_cflags "-I/System/Library/Frameworks/JavaVM.framework/Versions/Current/Headers/"
  end

  def oracle_java_os
    :darwin
  end
end
