require "vendor/macho/macho"

module RubyMachO
  # @private
  def macho
    @macho ||= begin
      MachO.open(to_s)
    end
  end

  # @private
  def mach_data
    @mach_data ||= begin
      machos = []
      mach_data = []

      if MachO.fat_magic?(macho.magic)
        machos = macho.machos
      else
        machos << macho
      end

      machos.each do |m|
        arch = case m.cputype
        when "CPU_TYPE_I386" then :i386
        when "CPU_TYPE_X86_64" then :x86_64
        when "CPU_TYPE_POWERPC" then :ppc7400
        when "CPU_TYPE_POWERPC64" then :ppc64
        else :dunno
        end

        type = case m.filetype
        when "MH_EXECUTE" then :executable
        when "MH_DYLIB" then :dylib
        when "MH_BUNDLE" then :bundle
        else :dunno
        end

        mach_data << { :arch => arch, :type => type }
      end

      mach_data
    rescue MachO::NotAMachOError
      # Silently ignore errors that indicate the file is not a Mach-O binary ...
      []
    rescue
      # ... but complain about other (parse) errors for further investigation.
      if ARGV.homebrew_developer?
        onoe "Failed to read Mach-O binary: #{self}"
        raise
      end
      []
    end
  end

  def dynamically_linked_libraries
    macho.linked_dylibs
  end

  def dylib_id
    macho.dylib_id
  end
end
