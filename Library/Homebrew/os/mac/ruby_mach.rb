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

      if MachO::Utils.fat_magic?(macho.magic)
        machos = macho.machos
      else
        machos << macho
      end

      machos.each do |m|
        arch = case m.cputype
        when :x86_64, :i386, :ppc64 then m.cputype
        when :ppc then :ppc7400
        else :dunno
        end

        type = case m.filetype
        when :dylib, :bundle then m.filetype
        when :execute then :executable
        else :dunno
        end

        mach_data << { arch: arch, type: type }
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
