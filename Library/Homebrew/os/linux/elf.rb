require "os/linux/architecture_list"

module ELF
  # @private
  LDD_RX = /\t.* => (.*) \(.*\)/

  # ELF data
  # @private
  def elf_data
    @elf_data ||= begin
      header = read(8).unpack("N2")
      case header[0]
      when 0x7f454c46 # ELF
        arch = case read(2, 18).unpack("v")[0]
        when 3 then :i386
        when 62 then :x86_64
        else :dunno
        end
        type = case read(2, 16).unpack("v")[0]
        when 2 then :executable
        when 3 then :dylib
        else :dunno
        end
        [{ arch: arch, type: type }]
      else
        raise "Not an ELF binary."
      end
    rescue
      []
    end
  end

  # @private
  class Metadata
    attr_reader :path, :dylib_id, :dylibs

    def initialize(path)
      @path = path

      @dylib_id = if path.dylib?
        command = ["patchelf", "--print-soname", path.expand_path.to_s]
        id = Utils.popen_read(*command).split("\n")
        raise ErrorDuringExecution, command unless $?.success?
        id
      end

      command = ["ldd", path.expand_path.to_s]
      @dylibs = Utils.popen_read(*command).split("\n")
      raise ErrorDuringExecution, command unless $?.success?
      @dylibs.map! { |lib| lib[LDD_RX, 1] }.compact!
    end
  end

  # @private
  def metadata
    @metadata ||= Metadata.new(self)
  end

  # Returns an array containing all dynamically-linked libraries, based on the
  # output of ldd.
  # Returns an empty array both for software that links against no libraries,
  # and for non-ELF objects.
  # @private
  def dynamically_linked_libraries(except: :none)
    # The argument except is unused.
    puts if except == :unused
    metadata.dylibs
  end

  # Return the SONAME of an ELF shared library.
  # @private
  def dylib_id
    metadata.dylib_id
  end

  def archs
    elf_data.map { |m| m.fetch :arch }.extend(ArchitectureListExtension)
  end

  def arch
    archs.length == 1 ? archs.first : :dunno
  end

  def universal?
    false
  end

  def i386?
    arch == :i386
  end

  def x86_64?
    arch == :x86_64
  end

  def ppc7400?
    arch == :ppc7400
  end

  def ppc64?
    arch == :ppc64
  end

  # @private
  def dylib?
    elf_data.any? { |m| m.fetch(:type) == :dylib }
  end

  # @private
  def mach_o_executable?
    elf_data.any? { |m| m.fetch(:type) == :executable }
  end

  # @private
  def mach_o_bundle?
    elf_data.any? { |m| m.fetch(:type) == :bundle }
  end
end
