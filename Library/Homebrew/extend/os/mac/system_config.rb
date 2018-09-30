class SystemConfig
  class << self
    undef describe_java, describe_homebrew_ruby

    def describe_java
      # java_home doesn't exist on all macOSs; it might be missing on older versions.
      return "N/A" unless File.executable? "/usr/libexec/java_home"

      out, _, status = system_command("/usr/libexec/java_home", args: ["--xml", "--failfast"], print_stderr: false)
      return "N/A" unless status.success?

      javas = []
      xml = REXML::Document.new(out)
      REXML::XPath.each(xml, "//key[text()='JVMVersion']/following-sibling::string") do |item|
        javas << item.text
      end
      javas.uniq.join(", ")
    end

    def describe_homebrew_ruby
      s = describe_homebrew_ruby_version

      if RUBY_PATH.to_s !~ %r{^/System/Library/Frameworks/Ruby\.framework/Versions/[12]\.[089]/usr/bin/ruby}
        "#{s} => #{RUBY_PATH}"
      else
        s
      end
    end

    def xcode
      @xcode ||= if MacOS::Xcode.installed?
        xcode = MacOS::Xcode.version.to_s
        xcode += " => #{MacOS::Xcode.prefix}" unless MacOS::Xcode.default_prefix?
        xcode
      end
    end

    def clt
      @clt ||= if MacOS::CLT.installed? && MacOS::Xcode.version >= "4.3"
        MacOS::CLT.version
      end
    end

    def clt_headers
      @clt_headers ||= if MacOS::CLT.headers_installed?
        MacOS::CLT.headers_version
      end
    end

    def xquartz
      @xquartz ||= if MacOS::XQuartz.installed?
        "#{MacOS::XQuartz.version} => #{describe_path(MacOS::XQuartz.prefix)}"
      end
    end

    def dump_verbose_config(f = $stdout)
      dump_generic_verbose_config(f)
      f.puts "macOS: #{MacOS.full_version}-#{kernel}"
      f.puts "CLT: #{clt || "N/A"}"
      f.puts "Xcode: #{xcode || "N/A"}"
      f.puts "CLT headers: #{clt_headers}" if MacOS::CLT.separate_header_package? && clt_headers
      f.puts "XQuartz: #{xquartz}" if !MacOS::XQuartz.provided_by_apple? && xquartz
    end
  end
end
