require "hardware"
require "software_spec"
require "rexml/document"
require "development_tools"

class SystemConfig
  class << self
    def clang
      @clang ||= if DevelopmentTools.installed?
        DevelopmentTools.clang_version
      else
        Version::NULL
      end
    end

    def clang_build
      @clang_build ||= if DevelopmentTools.installed?
        DevelopmentTools.clang_build_version
      else
        Version::NULL
      end
    end

    def head
      HOMEBREW_REPOSITORY.git_head || "(none)"
    end

    def last_commit
      HOMEBREW_REPOSITORY.git_last_commit || "never"
    end

    def origin
      HOMEBREW_REPOSITORY.git_origin || "(none)"
    end

    def core_tap_head
      CoreTap.instance.git_head || "(none)"
    end

    def core_tap_last_commit
      CoreTap.instance.git_last_commit || "never"
    end

    def core_tap_origin
      CoreTap.instance.remote || "(none)"
    end

    def describe_path(path)
      return "N/A" if path.nil?

      realpath = path.realpath
      if realpath == path
        path
      else
        "#{path} => #{realpath}"
      end
    end

    def describe_homebrew_ruby_version
      case RUBY_VERSION
      when /^1\.[89]/, /^2\.0/
        "#{RUBY_VERSION}-p#{RUBY_PATCHLEVEL}"
      else
        RUBY_VERSION
      end
    end

    def describe_homebrew_ruby
      "#{describe_homebrew_ruby_version} => #{RUBY_PATH}"
    end

    def hardware
      return if Hardware::CPU.type == :dunno

      "CPU: #{Hardware.cores_as_words}-core #{Hardware::CPU.bits}-bit #{Hardware::CPU.family}"
    end

    def kernel
      `uname -m`.chomp
    end

    def describe_java
      return "N/A" unless which "java"

      _, err, status = system_command("java", args: ["-version"], print_stderr: false)
      return "N/A" unless status.success?

      err[/java version "([\d\._]+)"/, 1] || "N/A"
    end

    def describe_git
      return "N/A" unless Utils.git_available?

      "#{Utils.git_version} => #{Utils.git_path}"
    end

    def describe_curl
      out, = system_command(curl_executable, args: ["--version"])

      if /^curl (?<curl_version>[\d\.]+)/ =~ out
        "#{curl_version} => #{curl_executable}"
      else
        "N/A"
      end
    end

    def dump_verbose_config(f = $stdout)
      f.puts "HOMEBREW_VERSION: #{HOMEBREW_VERSION}"
      f.puts "ORIGIN: #{origin}"
      f.puts "HEAD: #{head}"
      f.puts "Last commit: #{last_commit}"
      if CoreTap.instance.installed?
        f.puts "Core tap ORIGIN: #{core_tap_origin}"
        f.puts "Core tap HEAD: #{core_tap_head}"
        f.puts "Core tap last commit: #{core_tap_last_commit}"
      else
        f.puts "Core tap: N/A"
      end
      defaults_hash = {
        HOMEBREW_PREFIX: Homebrew::DEFAULT_PREFIX,
        HOMEBREW_REPOSITORY: Homebrew::DEFAULT_REPOSITORY,
        HOMEBREW_CELLAR: Homebrew::DEFAULT_CELLAR,
        HOMEBREW_CACHE: "#{ENV["HOME"]}/Library/Caches/Homebrew",
        HOMEBREW_TEMP: ENV["HOMEBREW_SYSTEM_TEMP"],
        HOMEBREW_RUBY_WARNINGS: "-W0",
        HOMEBREW_GIT: "git",
      }.freeze
      boring_keys = %w[
        HOMEBREW_BROWSER
        HOMEBREW_EDITOR

        HOMEBREW_ANALYTICS_ID
        HOMEBREW_ANALYTICS_USER_UUID
        HOMEBREW_AUTO_UPDATE_CHECKED
        HOMEBREW_BOTTLE_DEFAULT_DOMAIN
        HOMEBREW_BOTTLE_DOMAIN
        HOMEBREW_BREW_FILE
        HOMEBREW_COMMAND_DEPTH
        HOMEBREW_CURL
        HOMEBREW_GIT_CONFIG_FILE
        HOMEBREW_LIBRARY
        HOMEBREW_MACOS_VERSION
        HOMEBREW_MACOS_VERSION_NUMERIC
        HOMEBREW_RUBY_PATH
        HOMEBREW_SYSTEM
        HOMEBREW_SYSTEM_TEMP
        HOMEBREW_OS_VERSION
        HOMEBREW_PATH
        HOMEBREW_PROCESSOR
        HOMEBREW_PRODUCT
        HOMEBREW_USER_AGENT
        HOMEBREW_USER_AGENT_CURL
        HOMEBREW_VERSION
      ].freeze
      f.puts "HOMEBREW_PREFIX: #{HOMEBREW_PREFIX}"
      if defaults_hash[:HOMEBREW_REPOSITORY] != HOMEBREW_REPOSITORY.to_s
        f.puts "HOMEBREW_REPOSITORY: #{HOMEBREW_REPOSITORY}"
      end
      if defaults_hash[:HOMEBREW_CELLAR] != HOMEBREW_CELLAR.to_s
        f.puts "HOMEBREW_CELLAR: #{HOMEBREW_CELLAR}"
      end
      if defaults_hash[:HOMEBREW_CACHE] != HOMEBREW_CACHE.to_s
        f.puts "HOMEBREW_CACHE: #{HOMEBREW_CACHE}"
      end
      if defaults_hash[:HOMEBREW_TEMP] != HOMEBREW_TEMP.to_s
        f.puts "HOMEBREW_TEMP: #{HOMEBREW_TEMP}"
      end
      if defaults_hash[:HOMEBREW_RUBY_WARNINGS] != ENV["HOMEBREW_RUBY_WARNINGS"].to_s
        f.puts "HOMEBREW_RUBY_WARNINGS: #{ENV["HOMEBREW_RUBY_WARNINGS"]}"
      end
      if defaults_hash[:HOMEBREW_GIT] != ENV["HOMEBREW_GIT"].to_s
        f.puts "HOMEBREW_GIT: #{ENV["HOMEBREW_GIT"]}"
      end
      unless ENV["HOMEBREW_ENV"]
        ENV.sort.each do |key, value|
          next unless key.start_with?("HOMEBREW_")
          next if boring_keys.include?(key)
          next if defaults_hash[key.to_sym]

          value = "set" if key =~ /(cookie|key|token|password)/i
          f.puts "#{key}: #{value}"
        end
      end
      f.puts hardware if hardware
      f.puts "Homebrew Ruby: #{describe_homebrew_ruby}"
      f.print "Clang: "
      if clang.null?
        f.puts "N/A"
      else
        f.print "#{clang} build "
        if clang_build.null?
          f.puts "(parse error)"
        else
          f.puts clang_build
        end
      end
      f.puts "Git: #{describe_git}"
      f.puts "Curl: #{describe_curl}"
      f.puts "Java: #{describe_java}" if describe_java != "N/A"
    end
    alias dump_generic_verbose_config dump_verbose_config
  end
end

require "extend/os/system_config"
