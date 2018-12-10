module Language
  module Java
    def self.java_home_cmd(_ = nil)
      # macOS provides /usr/libexec/java_home, but Linux does not.
      raise NotImplementedError
    end

    def self.java_home(version = nil)
      req = JavaRequirement.new [*version]
      raise UnsatisfiedRequirements, req.message unless req.satisfied?
      req.java_home
    end

    # @private
    def self.java_home_shell(version = nil)
      java_home(version).to_s
    end

    def self.java_home_env(version = nil)
      { JAVA_HOME: java_home_shell(version) }
    end

    def self.overridable_java_home_env(version = nil)
      { JAVA_HOME: "${JAVA_HOME:-#{java_home_shell(version)}}" }
    end
  end
end

require "extend/os/language/java"
