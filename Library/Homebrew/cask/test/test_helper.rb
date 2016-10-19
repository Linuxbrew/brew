require "bundler"
require "bundler/setup"
require "pathname"

if ENV["HOMEBREW_TESTS_COVERAGE"]
  require "simplecov"
end

project_root = Pathname.new(File.expand_path("../..", __FILE__))
tap_root = Pathname.new(ENV["HOMEBREW_LIBRARY"]).join("Taps", "caskroom", "homebrew-cask")

# add Homebrew to load path
$LOAD_PATH.unshift(File.expand_path("#{ENV["HOMEBREW_REPOSITORY"]}/Library/Homebrew"))

require "global"

# add Homebrew-Cask to load path
$LOAD_PATH.push(project_root.join("lib").to_s)

require "test/helper/env"
require "test/helper/shutup"
include Test::Helper::Env
include Test::Helper::Shutup

def sudo(*args)
  %w[/usr/bin/sudo -E --] + Array(args).flatten
end

TEST_TMPDIR = Dir.mktmpdir("homebrew_cask_tests")
at_exit do
  FileUtils.remove_entry(TEST_TMPDIR)
end

# must be called after testing_env so at_exit hooks are in proper order
require "minitest/autorun"
require "minitest/reporters"
Minitest::Reporters.use! Minitest::Reporters::DefaultReporter.new(color: true)

require "parallel_tests/test/runtime_logger"

# Force mocha to patch MiniTest since we have both loaded thanks to homebrew's testing_env
require "mocha/api"
require "mocha/integration/mini_test"
Mocha::Integration::MiniTest.activate

# our baby
require "hbc"

# override Homebrew locations
Hbc.homebrew_prefix = Pathname.new(TEST_TMPDIR).join("prefix")
Hbc.homebrew_repository = Hbc.homebrew_prefix

# Override Tap::TAP_DIRECTORY to use our test Tap directory.
class Tap
  send(:remove_const, :TAP_DIRECTORY)
  TAP_DIRECTORY = Hbc.homebrew_prefix.join("Library", "Taps")
end

Hbc.default_tap = Tap.fetch("caskroom", "testcasks")

# also jack in some test Casks
FileUtils.ln_s project_root.join("test", "support"), Tap::TAP_DIRECTORY.join("caskroom").tap(&:mkpath).join("homebrew-testcasks")

# pretend that the caskroom/cask Tap is installed
FileUtils.ln_s tap_root, Tap::TAP_DIRECTORY.join("caskroom").tap(&:mkpath).join("homebrew-cask")

# create cache directory
Hbc.homebrew_cache = Pathname.new(TEST_TMPDIR).join("cache")
Hbc.cache.mkpath

# our own testy caskroom
Hbc.caskroom = Hbc.homebrew_prefix.join("TestCaskroom")

class TestHelper
  # helpers for test Casks to reference local files easily
  def self.local_binary_path(name)
    File.expand_path(File.join(File.dirname(__FILE__), "support", "binaries", name))
  end

  def self.local_binary_url(name)
    "file://" + local_binary_path(name)
  end

  def self.test_cask
    @test_cask ||= Hbc.load("basic-cask")
  end

  def self.fake_fetcher
    Hbc::FakeFetcher
  end

  def self.fake_response_for(*args)
    Hbc::FakeFetcher.fake_response_for(*args)
  end

  def self.valid_alias?(candidate)
    return false unless candidate.symlink?
    candidate.readlink.exist?
  end

  def self.install_without_artifacts(cask)
    Hbc::Installer.new(cask).tap do |i|
      shutup do
        i.download
        i.extract_primary_container
      end
    end
  end

  def self.install_with_caskfile(cask)
    Hbc::Installer.new(cask).tap do |i|
      shutup do
        i.save_caskfile
      end
    end
  end

  def self.install_without_artifacts_with_caskfile(cask)
    Hbc::Installer.new(cask).tap do |i|
      shutup do
        i.download
        i.extract_primary_container
        i.save_caskfile
      end
    end
  end
end

# Extend MiniTest API with support for RSpec-style shared examples
require "support/shared_examples"
require "support/shared_examples/dsl_base.rb"
require "support/shared_examples/staged.rb"

require "support/fake_fetcher"
require "support/fake_dirs"
require "support/fake_system_command"
require "support/cleanup"
require "support/never_sudo_system_command"
require "tmpdir"
require "tempfile"

# Common superclass for test Casks for when we need to filter them out
module Hbc
  class TestCask < Cask; end
end
