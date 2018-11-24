require "English"
require "json"
require "json/add/exception"
require "pathname"
require "ostruct"
require "pp"

require_relative "load_path"

require "active_support/core_ext/object/blank"
require "active_support/core_ext/numeric/time"
require "active_support/core_ext/array/access"
require "active_support/i18n"
require "active_support/inflector/inflections"

I18n.backend.available_locales # Initialize locales so they can be overwritten.
I18n.backend.store_translations :en, support: { array: { last_word_connector: " and " } }

ActiveSupport::Inflector.inflections(:en) do |inflect|
  inflect.irregular "formula", "formulae"
  inflect.irregular "is", "are"
  inflect.irregular "it", "they"
end

require "config"
require "os"
require "extend/ARGV"
require "messages"
require "system_command"

ARGV.extend(HomebrewArgvExtension)

HOMEBREW_PRODUCT = ENV["HOMEBREW_PRODUCT"]
HOMEBREW_VERSION = ENV["HOMEBREW_VERSION"]
HOMEBREW_WWW = "https://brew.sh".freeze

require "extend/git_repository"

HOMEBREW_REPOSITORY.extend(GitRepositoryExtension)

require "rbconfig"

RUBY_PATH = Pathname.new(RbConfig.ruby)
RUBY_BIN = RUBY_PATH.dirname

HOMEBREW_USER_AGENT_CURL = ENV["HOMEBREW_USER_AGENT_CURL"]
HOMEBREW_USER_AGENT_RUBY =
  "#{ENV["HOMEBREW_USER_AGENT"]} ruby/#{RUBY_VERSION}-p#{RUBY_PATCHLEVEL}".freeze
HOMEBREW_USER_AGENT_FAKE_SAFARI =
  "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_3) AppleWebKit/602.4.8 " \
  "(KHTML, like Gecko) Version/10.0.3 Safari/602.4.8".freeze

# Bintray fallback is here for people auto-updating from a version where
# `HOMEBREW_BOTTLE_DEFAULT_DOMAIN` isn't set.
HOMEBREW_BOTTLE_DEFAULT_DOMAIN = if ENV["HOMEBREW_BOTTLE_DEFAULT_DOMAIN"]
  ENV["HOMEBREW_BOTTLE_DEFAULT_DOMAIN"]
elsif OS.mac? || ENV["HOMEBREW_FORCE_HOMEBREW_ON_LINUX"]
  "https://homebrew.bintray.com".freeze
else
  "https://linuxbrew.bintray.com".freeze
end

HOMEBREW_BOTTLE_DOMAIN = ENV["HOMEBREW_BOTTLE_DOMAIN"] ||
                         HOMEBREW_BOTTLE_DEFAULT_DOMAIN

require "fileutils"
require "os"
require "os/global"

module Homebrew
  extend FileUtils

  DEFAULT_PREFIX ||= "/usr/local".freeze
  DEFAULT_CELLAR = "#{DEFAULT_PREFIX}/Cellar".freeze
  DEFAULT_REPOSITORY = "#{DEFAULT_PREFIX}/Homebrew".freeze

  class << self
    attr_writer :failed, :raise_deprecation_exceptions, :auditing, :args

    def Homebrew.default_prefix?(prefix = HOMEBREW_PREFIX)
      prefix.to_s == DEFAULT_PREFIX
    end

    def failed?
      @failed ||= false
      @failed == true
    end

    def args
      @args ||= OpenStruct.new
    end

    def messages
      @messages ||= Messages.new
    end

    def raise_deprecation_exceptions?
      @raise_deprecation_exceptions == true
    end

    def auditing?
      @auditing == true
    end
  end
end

HOMEBREW_PULL_API_REGEX =
  %r{https://api\.github\.com/repos/([\w-]+)/([\w-]+)?/pulls/(\d+)}.freeze
HOMEBREW_PULL_OR_COMMIT_URL_REGEX =
  %r[https://github\.com/([\w-]+)/([\w-]+)?/(?:pull/(\d+)|commit/[0-9a-fA-F]{4,40})].freeze

require "forwardable"
require "PATH"

ENV["HOMEBREW_PATH"] ||= ENV["PATH"]
ORIGINAL_PATHS = PATH.new(ENV["HOMEBREW_PATH"]).map do |p|
  begin
    Pathname.new(p).expand_path
  rescue
    nil
  end
end.compact.freeze

HOMEBREW_INTERNAL_COMMAND_ALIASES = {
  "ls"          => "list",
  "homepage"    => "home",
  "-S"          => "search",
  "up"          => "update",
  "ln"          => "link",
  "instal"      => "install", # gem does the same
  "uninstal"    => "uninstall",
  "rm"          => "uninstall",
  "remove"      => "uninstall",
  "configure"   => "diy",
  "abv"         => "info",
  "dr"          => "doctor",
  "--repo"      => "--repository",
  "environment" => "--env",
  "--config"    => "config",
  "-v"          => "--version",
}.freeze

require "set"

require "extend/pathname"

require "extend/module"
require "extend/predicable"
require "extend/string"
require "active_support/core_ext/object/blank"
require "active_support/core_ext/hash/deep_merge"
require "active_support/core_ext/file/atomic"

require "exceptions"
require "utils"

require "official_taps"
require "tap"
require "tap_constants"

if !ARGV.include?("--no-compat") && !ENV["HOMEBREW_NO_COMPAT"]
  require "compat"
end
