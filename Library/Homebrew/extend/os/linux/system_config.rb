class SystemConfig
  class << self
    def describe_system_gcc_version
      @describe_system_gcc_version ||= begin
        gcc = Pathname.new "/usr/bin/gcc"
        `#{gcc} --version 2>/dev/null`[/ (\d+\.\d+\.\d+)/, 1] if gcc.exist?
      end
    end

    def formula_version(formula)
      require "formula"
      begin
        f = Formula[formula]
        f.installed? ? f.version : "N/A"
      rescue FormulaUnavailableError
        # Fix for brew tests, which uses NullLoader.
        return "N/A"
      end
    end

    def dump_verbose_config(f = $stdout)
      dump_generic_verbose_config(f)
      f.puts "Kernel: #{`uname -mors`.chomp}"
      if which("lsb_release")
        f.puts `lsb_release -d`.chomp.sub("Description:\t", "OS: ")
        f.puts `lsb_release -c`.chomp.sub("\t", " ")
      else
        redhat_release = Pathname.new "/etc/redhat-release"
        f.puts "OS: #{redhat_release.read.chomp}" if redhat_release.readable?
      end
      f.puts "OS glibc: #{GlibcRequirement.system_version}"
      f.puts "OS gcc: #{describe_system_gcc_version}"
      f.puts "Linuxbrew glibc: #{formula_version "glibc"}"
      f.puts "Linuxbrew gcc: #{formula_version "gcc"}"
      f.puts "Linuxbrew xorg: #{formula_version "linuxbrew/xorg/xorg"}"
    end
  end
end
