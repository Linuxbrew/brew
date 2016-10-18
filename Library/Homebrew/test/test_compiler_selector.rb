require "testing_env"
require "compilers"
require "software_spec"

class CompilerSelectorTests < Homebrew::TestCase
  class Double < SoftwareSpec
    def <<(cc)
      fails_with(cc)
      self
    end
  end

  class CompilerVersions
    attr_accessor :gcc_4_0_build_version, :gcc_build_version,
      :clang_build_version

    def initialize
      @gcc_4_0_build_version = nil
      @gcc_build_version = 5666
      @clang_build_version = 425
    end

    def non_apple_gcc_version(name)
      case name
      when "gcc-4.8" then "4.8.1"
      when "gcc-4.7" then "4.7.1"
      end
    end
  end

  def setup
    @f  = Double.new
    @cc = :clang
    @versions = CompilerVersions.new
    @selector = CompilerSelector.new(
      @f, @versions, [:clang, :gcc, :llvm, :gnu]
    )
  end

  def actual_cc
    @selector.compiler
  end

  def test_all_compiler_failures
    @f << :clang << :llvm << :gcc << { gcc: "4.8" } << { gcc: "4.7" }
    assert_raises(CompilerSelectionError) { actual_cc }
  end

  def test_no_compiler_failures
    assert_equal @cc, actual_cc
  end

  def test_fails_with_clang
    @f << :clang
    assert_equal :gcc, actual_cc
  end

  def test_fails_with_llvm
    @f << :llvm
    assert_equal :clang, actual_cc
  end

  def test_fails_with_gcc
    @f << :gcc
    assert_equal :clang, actual_cc
  end

  def test_fails_with_non_apple_gcc
    @f << { gcc: "4.8" }
    assert_equal :clang, actual_cc
  end

  def test_mixed_failures_1
    @f << :clang << :gcc
    assert_equal "gcc-4.8", actual_cc
  end

  def test_mixed_failures_2
    @f << :clang << :llvm
    assert_equal :gcc, actual_cc
  end

  def test_mixed_failures_3
    @f << :gcc << :llvm
    assert_equal :clang, actual_cc
  end

  def test_mixed_failures_4
    @f << :clang << { gcc: "4.8" }
    assert_equal :gcc, actual_cc
  end

  def test_mixed_failures_5
    @f << :clang << :gcc << :llvm << { gcc: "4.8" }
    assert_equal "gcc-4.7", actual_cc
  end

  def test_gcc_precedence
    @f << :clang << :gcc
    assert_equal "gcc-4.8", actual_cc
  end

  def test_missing_gcc
    @versions.gcc_build_version = nil
    @f << :clang << :llvm << { gcc: "4.8" } << { gcc: "4.7" }
    assert_raises(CompilerSelectionError) { actual_cc }
  end

  def test_missing_llvm_and_gcc
    @versions.gcc_build_version = nil
    @f << :clang << { gcc: "4.8" } << { gcc: "4.7" }
    assert_raises(CompilerSelectionError) { actual_cc }
  end
end
