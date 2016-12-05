require "language/java"

class JavaRequirement < Requirement
  default_formula "jdk"

  env do
    next unless @java_home
    env_java_common
    if (Pathname.new(@java_home)/"include").exist? # Oracle JVM
      env_oracle_jdk
    end
  end

  private

  def oracle_java_os
    :linux
  end
end
