require "language/java"

class JavaRequirement < Requirement
  env do
    env_java_common
    env_oracle_jdk
  end

  def possible_javas
    javas = []
    javas << Pathname.new(ENV["JAVA_HOME"])/"bin/java" if ENV["JAVA_HOME"]
    %w[jdk jdk@8 jdk@7].each do |formula_name|
      begin
        java = Formula[formula_name].bin/"java"
        javas << java if java.executable?
      rescue FormulaUnavailableError
        nil
      end
    end
    which_java = which "java"
    javas << which_java if which_java
    javas
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
