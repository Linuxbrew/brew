require "hardware"
require "software_spec"
require "rexml/document"
require "tap"
require "development_tools"

class SystemConfig
  class << self
    def gcc_4_2
      @gcc_4_2 ||= if DevelopmentTools.installed?
        DevelopmentTools.gcc_4_2_build_version
      else
        Version::NULL
      end
    end

    def gcc_4_0
      @gcc_4_0 ||= if DevelopmentTools.installed?
        DevelopmentTools.gcc_4_0_build_version
      else
        Version::NULL
      end
    end

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

    def describe_perl
      describe_path(which("perl", ENV["HOMEBREW_PATH"]))
    end

    def describe_python
      python = begin
        python_path = PATH.new(ENV["HOMEBREW_PATH"])
                          .prepend(Formula["python"].opt_libexec/"bin")
        which "python", python_path
      rescue FormulaUnavailableError
        which "python"
      end

      return "N/A" if python.nil?
      python_binary = Utils.popen_read python, "-c", "import sys; sys.stdout.write(sys.executable)"
      python_binary = Pathname.new(python_binary).realpath
      if python == python_binary
        python
      else
        "#{python} => #{python_binary}"
      end
    end

    def describe_ruby
      ruby = which "ruby", ENV["HOMEBREW_PATH"]
      return "N/A" if ruby.nil?
      ruby_binary = Utils.popen_read ruby, "-rrbconfig", "-e", \
        'include RbConfig;print"#{CONFIG["bindir"]}/#{CONFIG["ruby_install_name"]}#{CONFIG["EXEEXT"]}"'
      ruby_binary = Pathname.new(ruby_binary).realpath
      if ruby == ruby_binary
        ruby
      else
        "#{ruby} => #{ruby_binary}"
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
      # java_home doesn't exist on all macOSs; it might be missing on older versions.
      return "N/A" unless File.executable? "/usr/libexec/java_home"

      java_xml = Utils.popen_read("/usr/libexec/java_home", "--xml", "--failfast", err: :close)
      return "N/A" unless $CHILD_STATUS.success?
      javas = []
      REXML::XPath.each(REXML::Document.new(java_xml), "//key[text()='JVMVersion']/following-sibling::string") do |item|
        javas << item.text
      end
      javas.uniq.join(", ")
    end

    def describe_git
      return "N/A" unless Utils.git_available?
      "#{Utils.git_version} => #{Utils.git_path}"
    end

    def describe_curl
      curl_version_output = Utils.popen_read("#{curl_executable} --version", err: :close)
      curl_version_output =~ /^curl ([\d\.]+)/
      curl_version = Regexp.last_match(1)
      "#{curl_version} => #{curl_executable}"
    rescue
      "N/A"
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
        HOMEBREW_PREFIX: "/usr/local",
        HOMEBREW_REPOSITORY: "/usr/local/Homebrew",
        HOMEBREW_CELLAR: "/usr/local/Cellar",
        HOMEBREW_CACHE: "#{ENV["HOME"]}/Library/Caches/Homebrew",
      }.freeze
      boring_keys = %w[
        HOMEBREW_BROWSER
        HOMEBREW_EDITOR

        HOMEBREW_ANALYTICS_ID
        HOMEBREW_ANALYTICS_USER_UUID
        HOMEBREW_AUTO_UPDATE_CHECKED
        HOMEBREW_BREW_FILE
        HOMEBREW_COMMAND_DEPTH
        HOMEBREW_CURL
        HOMEBREW_GIT_CONFIG_FILE
        HOMEBREW_LIBRARY
        HOMEBREW_MACOS_VERSION
        HOMEBREW_RUBY_PATH
        HOMEBREW_SYSTEM
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
      ENV.sort.each do |key, value|
        next unless key.start_with?("HOMEBREW_")
        next if boring_keys.include?(key)
        next if defaults_hash[key.to_sym] == value
        value = "set" if key =~ /(cookie|key|token|password)/i
        f.puts "#{key}: #{value}"
      end
      f.puts hardware if hardware
      f.puts "Homebrew Ruby: #{describe_homebrew_ruby}"
      f.puts "GCC-4.0: build #{gcc_4_0}" unless gcc_4_0.null?
      f.puts "GCC-4.2: build #{gcc_4_2}" unless gcc_4_2.null?
      f.puts "Clang: #{clang.null? ? "N/A" : "#{clang} build #{clang_build}"}"
      f.puts "Git: #{describe_git}"
      f.puts "Curl: #{describe_curl}"
      f.puts "Perl: #{describe_perl}"
      f.puts "Python: #{describe_python}"
      f.puts "Ruby: #{describe_ruby}"
      f.puts "Java: #{describe_java}"
    end
    alias dump_generic_verbose_config dump_verbose_config
  end
end

require "extend/os/system_config"
