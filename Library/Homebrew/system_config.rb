require "hardware"
require "software_spec"
require "rexml/document"
require "tap"
require "development_tools"

class SystemConfig
  class << self
    def gcc_42
      @gcc_42 ||= DevelopmentTools.gcc_42_build_version if DevelopmentTools.installed?
    end

    def gcc_40
      @gcc_40 ||= DevelopmentTools.gcc_40_build_version if DevelopmentTools.installed?
    end

    def clang
      @clang ||= DevelopmentTools.clang_version if DevelopmentTools.installed?
    end

    def clang_build
      @clang_build ||= DevelopmentTools.clang_build_version if DevelopmentTools.installed?
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
      describe_path(which("perl"))
    end

    def describe_python
      python = which "python"
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
      ruby = which "ruby"
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

      java_xml = Utils.popen_read("/usr/libexec/java_home", "--xml", "--failfast")
      return "N/A" unless $?.success?
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
      f.puts "HOMEBREW_PREFIX: #{HOMEBREW_PREFIX}"
      f.puts "HOMEBREW_REPOSITORY: #{HOMEBREW_REPOSITORY}"
      f.puts "HOMEBREW_CELLAR: #{HOMEBREW_CELLAR}"
      f.puts "HOMEBREW_BOTTLE_DOMAIN: #{BottleSpecification::DEFAULT_DOMAIN}"
      f.puts hardware if hardware
      f.puts "Homebrew Ruby: #{describe_homebrew_ruby}"
      f.puts "GCC-4.0: build #{gcc_40}" unless gcc_40.null?
      f.puts "GCC-4.2: build #{gcc_42}" unless gcc_42.null?
      f.puts "Clang: #{clang.null? ? "N/A" : "#{clang} build #{clang_build}"}"
      f.puts "Git: #{describe_git}"
      f.puts "Perl: #{describe_perl}"
      f.puts "Python: #{describe_python}"
      f.puts "Ruby: #{describe_ruby}"
      f.puts "Java: #{describe_java}"
    end
    alias dump_generic_verbose_config dump_verbose_config
  end
end

require "extend/os/system_config"
