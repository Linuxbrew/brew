require "bundler"
require "bundler/setup"
require "pathname"

require "simplecov" if ENV["HOMEBREW_TESTS_COVERAGE"]

# add Homebrew to load path
$LOAD_PATH.unshift(File.expand_path("#{ENV["HOMEBREW_REPOSITORY"]}/Library/Homebrew"))
$LOAD_PATH.unshift(File.expand_path("#{ENV["HOMEBREW_REPOSITORY"]}/Library/Homebrew/test/lib"))

require "global"

# add Homebrew-Cask to load path
$LOAD_PATH.push(HOMEBREW_LIBRARY_PATH.join("cask", "lib").to_s)

require "test/helper/env"
require "test/helper/shutup"
include Test::Helper::Env
include Test::Helper::Shutup

def sudo(*args)
  %w[/usr/bin/sudo -E --] + args.flatten
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

module Hbc
  class TestCask < Cask; end
end

# create and override default directories
Hbc.appdir = Pathname.new(TEST_TMPDIR).join("Applications").tap(&:mkpath)
Hbc.cache.mkpath
Hbc.caskroom = Hbc.default_caskroom.tap(&:mkpath)
Hbc.default_tap = Tap.fetch("caskroom", "test").tap do |tap|
  # link test casks
  FileUtils.mkdir_p tap.path.dirname
  FileUtils.ln_s Pathname.new(__FILE__).dirname.join("support"), tap.path
end

# pretend that the caskroom/cask Tap is installed
FileUtils.ln_s Pathname.new(ENV["HOMEBREW_LIBRARY"]).join("Taps", "caskroom", "homebrew-cask"), Tap.fetch("caskroom", "cask").path

class TestHelper
  # helpers for test Casks to reference local files easily
  def self.local_binary_path(name)
    File.expand_path(File.join(File.dirname(__FILE__), "support", "binaries", name))
  end

  def self.local_binary_url(name)
    "file://" + local_binary_path(name)
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

require "support/fake_dirs"
require "support/fake_system_command"
require "support/cleanup"
require "support/never_sudo_system_command"
require "tmpdir"
require "tempfile"
