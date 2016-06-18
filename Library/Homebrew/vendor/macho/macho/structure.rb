module MachO
  # A general purpose pseudo-structure.
  # @abstract
  class MachOStructure
    # The String#unpack format of the data structure.
    FORMAT = ""

    # The size of the data structure, in bytes.
    SIZEOF = 0

    # @return [Fixnum] the size, in bytes, of the represented structure.
    def self.bytesize
      self::SIZEOF
    end

    # @param endianness [Symbol] either :big or :little
    # @param bin [String] the string to be unpacked into the new structure
    # @return [MachO::MachOStructure] a new MachOStructure initialized with `bin`
    # @api private
    def self.new_from_bin(endianness, bin)
      format = specialize_format(self::FORMAT, endianness)

      self.new(*bin.unpack(format))
    end

    private

    # Convert an abstract (native-endian) String#unpack format to big or little.
    # @param format [String] the format string being converted
    # @param endianness [Symbol] either :big or :little
    # @return [String] the converted string
    # @api private
    def self.specialize_format(format, endianness)
      modifier = (endianness == :big) ? ">" : "<"
      format.tr("=", modifier)
    end
  end
end
