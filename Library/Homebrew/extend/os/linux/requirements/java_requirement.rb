require "language/java"

class JavaRequirement < Requirement
  env do
    env_java_common
    env_oracle_jdk
  end

  alias old_message message

  def message
    old_message + <<~EOS
      To install it, run:
        brew install jdk
    EOS
  end

  private

  def oracle_java_os
    :linux
  end
end
