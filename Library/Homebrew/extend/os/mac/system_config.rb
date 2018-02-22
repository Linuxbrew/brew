class SystemConfig
  class << self
    def xcode
      if instance_variable_defined?(:@xcode)
        @xcode
      elsif MacOS::Xcode.installed?
        @xcode = MacOS::Xcode.version.to_s
        @xcode += " => #{MacOS::Xcode.prefix}" unless MacOS::Xcode.default_prefix?
        @xcode
      end
    end

    def clt
      if instance_variable_defined?(:@clt)
        @clt
      elsif MacOS::CLT.installed? && MacOS::Xcode.version >= "4.3"
        @clt = MacOS::CLT.version
      end
    end

    def macports_or_fink
      @ponk ||= MacOS.macports_or_fink
      @ponk.join(", ") unless @ponk.empty?
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

    def describe_xquartz
      return "N/A" unless MacOS::XQuartz.installed?
      "#{MacOS::XQuartz.version} => #{describe_path(MacOS::XQuartz.prefix)}"
    end

    def describe_homebrew_ruby
      s = describe_homebrew_ruby_version

      if RUBY_PATH.to_s !~ %r{^/System/Library/Frameworks/Ruby\.framework/Versions/[12]\.[089]/usr/bin/ruby}
        "#{s} => #{RUBY_PATH}"
      else
        s
      end
    end

    def dump_verbose_config(f = $stdout)
      dump_generic_verbose_config(f)
      f.puts "macOS: #{MacOS.full_version}-#{kernel}"
      f.puts "Xcode: #{xcode ? xcode : "N/A"}"
      f.puts "CLT: #{clt ? clt : "N/A"}"
      f.puts "X11: #{describe_xquartz}"
      f.puts "MacPorts/Fink: #{macports_or_fink}" if macports_or_fink
    end
  end
end
