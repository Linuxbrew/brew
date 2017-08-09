class JavaRequirement < Requirement
  cask "java"

  env do
    env_java_common
    env_oracle_jdk || env_apple
  end

  private

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
