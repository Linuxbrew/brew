require "language/java"

describe Language::Java do
  describe "::java_home" do
    it "returns valid JAVA_HOME if version is specified", :needs_java do
      java_home = described_class.java_home("1.8+")
      expect(java_home/"bin/java").to be_an_executable
    end

    it "returns valid JAVA_HOME if version is not specified", :needs_java do
      java_home = described_class.java_home
      expect(java_home/"bin/java").to be_an_executable
    end
  end

  describe "::java_home_env" do
    it "returns java_home path with version if version specified", :needs_macos do
      java_home = described_class.java_home_env("blah")
      expect(java_home[:JAVA_HOME]).to include("--version blah")
    end

    it "returns java_home path without version if version is not specified", :needs_java do
      java_home = described_class.java_home_env
      expect(java_home[:JAVA_HOME]).not_to include("--version")
    end
  end

  describe "::overridable_java_home_env" do
    it "returns java_home path with version if version specified", :needs_macos do
      java_home = described_class.overridable_java_home_env("blah")
      expect(java_home[:JAVA_HOME]).to include("--version blah")
    end

    it "returns java_home path without version if version is not specified", :needs_java do
      java_home = described_class.overridable_java_home_env
      expect(java_home[:JAVA_HOME]).not_to include("--version")
    end
  end
end
