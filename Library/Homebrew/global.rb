require "extend/module"
require "extend/fileutils"
require "extend/pathname"
require "extend/git_repository"
require "extend/ARGV"
require "extend/string"
require "os"
require "utils"
require "exceptions"
require "set"
require "rbconfig"
require "official_taps"

ARGV.extend(HomebrewArgvExtension)

HOMEBREW_PRODUCT = ENV["HOMEBREW_PRODUCT"]
HOMEBREW_VERSION = ENV["HOMEBREW_VERSION"]
HOMEBREW_WWW = "http://brew.sh".freeze

require "config"

HOMEBREW_REPOSITORY.extend(GitRepositoryExtension)

RUBY_PATH = Pathname.new(RbConfig.ruby)
RUBY_BIN = RUBY_PATH.dirname

HOMEBREW_USER_AGENT_CURL = ENV["HOMEBREW_USER_AGENT_CURL"]
HOMEBREW_USER_AGENT_RUBY = "#{ENV["HOMEBREW_USER_AGENT"]} ruby/#{RUBY_VERSION}-p#{RUBY_PATCHLEVEL}".freeze

HOMEBREW_CURL_ARGS = [
  "--fail",
  "--progress-bar",
  "--remote-time",
  "--location",
  "--user-agent", HOMEBREW_USER_AGENT_CURL
].freeze

require "tap_constants"

module Homebrew
  extend FileUtils

  class << self
    attr_writer :failed

    def failed?
      @failed == true
    end

    attr_writer :raise_deprecation_exceptions

    def raise_deprecation_exceptions?
      @raise_deprecation_exceptions == true
    end
  end
end

HOMEBREW_PULL_API_REGEX = %r{https://api\.github\.com/repos/([\w-]+)/([\w-]+)?/pulls/(\d+)}
HOMEBREW_PULL_OR_COMMIT_URL_REGEX = %r[https://github\.com/([\w-]+)/([\w-]+)?/(?:pull/(\d+)|commit/[0-9a-fA-F]{4,40})]

require "compat" unless ARGV.include?("--no-compat") || ENV["HOMEBREW_NO_COMPAT"]

ORIGINAL_PATHS = ENV["PATH"].split(File::PATH_SEPARATOR).map do |p|
  begin
    Pathname.new(p).expand_path
  rescue
    nil
  end
end.compact.freeze

# TODO: remove this as soon as it's removed from commands.rb.
HOMEBREW_INTERNAL_COMMAND_ALIASES = {
  "ls" => "list",
  "homepage" => "home",
  "-S" => "search",
  "up" => "update",
  "ln" => "link",
  "instal" => "install", # gem does the same
  "rm" => "uninstall",
  "remove" => "uninstall",
  "configure" => "diy",
  "abv" => "info",
  "dr" => "doctor",
  "--repo" => "--repository",
  "environment" => "--env",
  "--config" => "config",
}.freeze
