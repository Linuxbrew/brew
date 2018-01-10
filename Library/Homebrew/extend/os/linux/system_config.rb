require "formula"
require "os/linux/glibc"

class SystemConfig
  class << self
    def host_os_version
      if which("lsb_release")
        description = `lsb_release -d`.chomp.sub("Description:\t", "")
        codename = `lsb_release -c`.chomp.sub("Codename:\t", "")
        "#{description} (#{codename})"
      elsif (redhat_release = Pathname.new("/etc/redhat-release")).readable?
        redhat_release.read.chomp
      else
        "N/A"
      end
    end

    def host_glibc_version
      version = OS::Linux::Glibc.system_version
      return "N/A" if version.null?
      version
    end

    def host_gcc_version
      gcc = Pathname.new "/usr/bin/gcc"
      return "N/A" unless gcc.executable?
      `#{gcc} --version 2>/dev/null`[/ (\d+\.\d+\.\d+)/, 1]
    end

    def formula_linked_version(formula)
      return "N/A" unless CoreTap.instance.installed?
      Formulary.factory(formula).linked_version || "N/A"
    rescue FormulaUnavailableError
      return "N/A"
    end

    def dump_verbose_config(out = $stdout)
      dump_generic_verbose_config(out)
      out.puts "Kernel: #{`uname -mors`.chomp}"
      out.puts "OS: #{host_os_version}"
      out.puts "Host glibc: #{host_glibc_version}"
      out.puts "/usr/bin/gcc: #{host_gcc_version}"
      ["glibc", "gcc", "xorg"].each do |f|
        out.puts "#{f}: #{formula_linked_version f}"
      end
    end
  end
end
