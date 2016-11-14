$:.unshift File.expand_path("../..", __FILE__)
$:.unshift File.expand_path("../lib", __FILE__)

require "simplecov" if ENV["HOMEBREW_TESTS_COVERAGE"]
require "global"
require "formulary"

# Test environment setup
(HOMEBREW_LIBRARY/"Taps/homebrew/homebrew-core/Formula").mkpath
%w[cache formula_cache locks cellar logs temp].each { |d| HOMEBREW_PREFIX.parent.join(d).mkpath }

# Test fixtures and files can be found relative to this path
TEST_DIRECTORY = File.dirname(File.expand_path(__FILE__))

begin
  require "rubygems"
  require "minitest/autorun"
  require "parallel_tests/test/runtime_logger"
  require "mocha/setup"
rescue LoadError
  abort "Run `bundle install` or install the mocha and minitest gems before running the tests"
end

module Homebrew
  module VersionAssertions
    def version(v)
      Version.create(v)
    end

    def assert_version_equal(expected, actual)
      assert_equal Version.create(expected), actual
    end

    def assert_version_detected(expected, url, specs = {})
      assert_equal expected, Version.detect(url, specs).to_s
    end

    def assert_version_nil(url)
      assert Version.parse(url).null?
    end
  end

  module FSLeakLogger
    def self.included(klass)
      require "find"
      @@log = File.open("#{__dir__}/fs_leak_log", "w")
      klass.make_my_diffs_pretty!
    end

    def before_setup
      @__files_before_test = []
      Find.find(TEST_TMPDIR) { |f| @__files_before_test << f.sub(TEST_TMPDIR, "") }
      super
    end

    def after_teardown
      super
      files_after_test = []
      Find.find(TEST_TMPDIR) { |f| files_after_test << f.sub(TEST_TMPDIR, "") }
      return if @__files_before_test == files_after_test
      @@log.puts location, diff(@__files_before_test, files_after_test)
    end
  end

  class TestCase < ::Minitest::Test
    require "test/helper/env"
    require "test/helper/shutup"
    include Test::Helper::Env
    include Test::Helper::Shutup

    include VersionAssertions
    include FSLeakLogger

    TEST_SHA1   = "deadbeefdeadbeefdeadbeefdeadbeefdeadbeef".freeze
    TEST_SHA256 = "deadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef".freeze

    def formula(name = "formula_name", path = Formulary.core_path(name), spec = :stable, alias_path: nil, &block)
      @_f = Class.new(Formula, &block).new(name, path, spec, alias_path: alias_path)
    end

    def mktmpdir(prefix_suffix = nil, &block)
      Dir.mktmpdir(prefix_suffix, HOMEBREW_TEMP, &block)
    end

    def needs_compat
      skip "Requires compat/ code" if ENV["HOMEBREW_NO_COMPAT"]
    end

    def needs_python
      skip "Requires Python" unless which("python")
    end

    def assert_nothing_raised
      yield
    end

    def assert_eql(exp, act, msg = nil)
      msg = message(msg, "") { diff exp, act }
      assert exp.eql?(act), msg
    end

    def refute_eql(exp, act, msg = nil)
      msg = message(msg) do
        "Expected #{mu_pp(act)} to not be eql to #{mu_pp(exp)}"
      end
      refute exp.eql?(act), msg
    end

    def dylib_path(name)
      Pathname.new("#{TEST_DIRECTORY}/mach/#{name}.dylib")
    end

    def bundle_path(name)
      Pathname.new("#{TEST_DIRECTORY}/mach/#{name}.bundle")
    end

    # Use a stubbed {Formulary::FormulaLoader} to make a given formula be found
    # when loading from {Formulary} with `ref`.
    def stub_formula_loader(formula, ref = formula.full_name)
      loader = mock
      loader.stubs(:get_formula).returns(formula)
      Formulary.stubs(:loader_for).with(ref, from: :keg).returns(loader)
      Formulary.stubs(:loader_for).with(ref, from: nil).returns(loader)
    end
  end
end
