require "testing_env"
require "requirements/java_requirement"
require "fileutils"

class OSMacJavaRequirementTests < Homebrew::TestCase
  def setup
    super
    @java_req = JavaRequirement.new(%w[1.8])
    @tmp_java_home = mktmpdir
    @tmp_pathname = Pathname.new(@tmp_java_home)
    FileUtils.mkdir @tmp_pathname/"bin"
    FileUtils.touch @tmp_pathname/"bin/java"
    @java_req.stubs(:preferred_java).returns(@tmp_pathname/"bin/java")
    @java_req.satisfied?
  end

  def test_java_env_apple
    ENV.expects(:prepend_path)
    ENV.expects(:append_to_cflags)
    @java_req.modify_build_environment
    assert_equal ENV["JAVA_HOME"], @tmp_java_home
  end

  def test_java_env_oracle
    FileUtils.mkdir @tmp_pathname/"include"
    ENV.expects(:prepend_path)
    ENV.expects(:append_to_cflags).twice
    @java_req.modify_build_environment
    assert_equal ENV["JAVA_HOME"], @tmp_java_home
  end
end
