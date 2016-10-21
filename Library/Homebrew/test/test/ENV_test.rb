require "testing_env"
require "extend/ENV"
require "helper/integration_command_test_case"

class IntegrationCommandTestEnv < IntegrationCommandTestCase
  def test_env
    assert_match(/CMAKE_PREFIX_PATH="#{Regexp.escape(HOMEBREW_PREFIX)}[:"]/,
                 cmd("--env"))
  end

  def test_env_fish
    assert_match(/set [-]gx CMAKE_PREFIX_PATH "#{Regexp.quote(HOMEBREW_PREFIX.to_s)}"/,
                 cmd("--env", "--shell=fish"))
  end

  def test_env_csh
    assert_match(/setenv CMAKE_PREFIX_PATH #{Regexp.quote(HOMEBREW_PREFIX.to_s)};/,
                 cmd("--env", "--shell=tcsh"))
  end

  def test_env_bash
    assert_match(/export CMAKE_PREFIX_PATH="#{Regexp.quote(HOMEBREW_PREFIX.to_s)}"/,
                 cmd("--env", "--shell=bash"))
  end

  def test_env_plain
    assert_match(/CMAKE_PREFIX_PATH: #{Regexp.quote(HOMEBREW_PREFIX)}/,
                 cmd("--env", "--plain"))
  end
end

module SharedEnvTests
  def setup
    @env = {}.extend(EnvActivation)
  end

  def test_switching_compilers
    @env.clang
    assert_nil @env["LD"]
    assert_equal @env["OBJC"], @env["CC"]
  end

  def test_with_build_environment_restores_env
    before = @env.dup
    @env.with_build_environment do
      @env["foo"] = "bar"
    end
    assert_nil @env["foo"]
    assert_equal before, @env
  end

  def test_with_build_environment_ensures_env_restored
    before = @env.dup
    begin
      @env.with_build_environment do
        @env["foo"] = "bar"
        raise Exception
      end
    rescue Exception
    end
    assert_nil @env["foo"]
    assert_equal before, @env
  end

  def test_with_build_environment_returns_block_value
    assert_equal 1, @env.with_build_environment { 1 }
  end

  def test_with_build_environment_does_not_mutate_interface
    expected = @env.methods
    @env.with_build_environment { assert_equal expected, @env.methods }
    assert_equal expected, @env.methods
  end

  def test_append_existing_key
    @env["foo"] = "bar"
    @env.append "foo", "1"
    assert_equal "bar 1", @env["foo"]
  end

  def test_append_existing_key_empty
    @env["foo"] = ""
    @env.append "foo", "1"
    assert_equal "1", @env["foo"]
  end

  def test_append_missing_key
    @env.append "foo", "1"
    assert_equal "1", @env["foo"]
  end

  def test_prepend_existing_key
    @env["foo"] = "bar"
    @env.prepend "foo", "1"
    assert_equal "1 bar", @env["foo"]
  end

  def test_prepend_existing_key_empty
    @env["foo"] = ""
    @env.prepend "foo", "1"
    assert_equal "1", @env["foo"]
  end

  def test_prepend_missing_key
    @env.prepend "foo", "1"
    assert_equal "1", @env["foo"]
  end

  # NOTE: this may be a wrong behavior; we should probably reject objects that
  # do not respond to #to_str. For now this documents existing behavior.
  def test_append_coerces_value_to_string
    @env.append "foo", 42
    assert_equal "42", @env["foo"]
  end

  def test_prepend_coerces_value_to_string
    @env.prepend "foo", 42
    assert_equal "42", @env["foo"]
  end

  def test_append_path
    @env.append_path "FOO", "/usr/bin"
    assert_equal "/usr/bin", @env["FOO"]
    @env.append_path "FOO", "/bin"
    assert_equal "/usr/bin#{File::PATH_SEPARATOR}/bin", @env["FOO"]
  end

  def test_prepend_path
    @env.prepend_path "FOO", "/usr/bin"
    assert_equal "/usr/bin", @env["FOO"]
    @env.prepend_path "FOO", "/bin"
    assert_equal "/bin#{File::PATH_SEPARATOR}/usr/bin", @env["FOO"]
  end

  def test_switching_compilers_updates_compiler
    [:clang, :gcc, :gcc_4_0].each do |compiler|
      @env.send(compiler)
      assert_equal compiler, @env.compiler
    end
  end

  def test_deparallelize_block_form_restores_makeflags
    @env["MAKEFLAGS"] = "-j4"
    @env.deparallelize do
      assert_nil @env["MAKEFLAGS"]
    end
    assert_equal "-j4", @env["MAKEFLAGS"]
  end
end

class StdenvTests < Homebrew::TestCase
  include SharedEnvTests

  def setup
    super
    @env.extend(Stdenv)
  end
end

class SuperenvTests < Homebrew::TestCase
  include SharedEnvTests

  def setup
    super
    @env.extend(Superenv)
  end

  def test_initializes_deps
    assert_equal [], @env.deps
    assert_equal [], @env.keg_only_deps
  end

  def test_unsupported_cxx11
    %w[gcc gcc-4.7].each do |compiler|
      @env["HOMEBREW_CC"] = compiler
      assert_raises do
        @env.cxx11
      end
      refute_match "x", @env["HOMEBREW_CCCFG"]
    end
  end

  def test_supported_cxx11_gcc_5
    @env["HOMEBREW_CC"] = "gcc-5"
    @env.cxx11
    assert_match "x", @env["HOMEBREW_CCCFG"]
  end

  def test_supported_cxx11_gcc_6
    @env["HOMEBREW_CC"] = "gcc-6"
    @env.cxx11
    assert_match "x", @env["HOMEBREW_CCCFG"]
  end

  def test_supported_cxx11_clang
    @env["HOMEBREW_CC"] = "clang"
    @env.cxx11
    assert_match "x", @env["HOMEBREW_CCCFG"]
    assert_match "g", @env["HOMEBREW_CCCFG"]
  end
end
