module MachO
  # A collection of utility functions used throughout ruby-macho.
  module Utils
    # Rounds a value to the next multiple of the given round.
    # @param value [Fixnum] the number being rounded
    # @param round [Fixnum] the number being rounded with
    # @return [Fixnum] the rounded value
    # @see http://www.opensource.apple.com/source/cctools/cctools-870/libstuff/rnd.c
    def self.round(value, round)
      round -= 1
      value += round
      value &= ~round
      value
    end

    # Returns the number of bytes needed to pad the given size to the given
    #  alignment.
    # @param size [Fixnum] the unpadded size
    # @param alignment [Fixnum] the number to alignment the size with
    # @return [Fixnum] the number of pad bytes required
    def self.padding_for(size, alignment)
      round(size, alignment) - size
    end

    # Converts an abstract (native-endian) String#unpack format to big or
    #  little.
    # @param format [String] the format string being converted
    # @param endianness [Symbol] either `:big` or `:little`
    # @return [String] the converted string
    def self.specialize_format(format, endianness)
      modifier = endianness == :big ? ">" : "<"
      format.tr("=", modifier)
    end

    # Packs tagged strings into an aligned payload.
    # @param fixed_offset [Fixnum] the baseline offset for the first packed
    #  string
    # @param alignment [Fixnum] the alignment value to use for packing
    # @param strings [Hash] the labeled strings to pack
    # @return [Array<String, Hash>] the packed string and labeled offsets
    def self.pack_strings(fixed_offset, alignment, strings = {})
      offsets = {}
      next_offset = fixed_offset
      payload = ""

      strings.each do |key, string|
        offsets[key] = next_offset
        payload << string
        payload << "\x00"
        next_offset += string.bytesize + 1
      end

      payload << "\x00" * padding_for(fixed_offset + payload.bytesize, alignment)
      [payload, offsets]
    end

    # Compares the given number to valid Mach-O magic numbers.
    # @param num [Fixnum] the number being checked
    # @return [Boolean] whether `num` is a valid Mach-O magic number
    def self.magic?(num)
      Headers::MH_MAGICS.key?(num)
    end

    # Compares the given number to valid Fat magic numbers.
    # @param num [Fixnum] the number being checked
    # @return [Boolean] whether `num` is a valid Fat magic number
    def self.fat_magic?(num)
      num == Headers::FAT_MAGIC
    end

    # Compares the given number to valid 32-bit Mach-O magic numbers.
    # @param num [Fixnum] the number being checked
    # @return [Boolean] whether `num` is a valid 32-bit magic number
    def self.magic32?(num)
      num == Headers::MH_MAGIC || num == Headers::MH_CIGAM
    end

    # Compares the given number to valid 64-bit Mach-O magic numbers.
    # @param num [Fixnum] the number being checked
    # @return [Boolean] whether `num` is a valid 64-bit magic number
    def self.magic64?(num)
      num == Headers::MH_MAGIC_64 || num == Headers::MH_CIGAM_64
    end

    # Compares the given number to valid little-endian magic numbers.
    # @param num [Fixnum] the number being checked
    # @return [Boolean] whether `num` is a valid little-endian magic number
    def self.little_magic?(num)
      num == Headers::MH_CIGAM || num == Headers::MH_CIGAM_64
    end

    # Compares the given number to valid big-endian magic numbers.
    # @param num [Fixnum] the number being checked
    # @return [Boolean] whether `num` is a valid big-endian magic number
    def self.big_magic?(num)
      num == Headers::MH_CIGAM || num == Headers::MH_CIGAM_64
    end
  end
end
