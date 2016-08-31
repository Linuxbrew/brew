module MachO
  # Opens the given filename as a MachOFile or FatFile, depending on its magic.
  # @param filename [String] the file being opened
  # @return [MachO::MachOFile] if the file is a Mach-O
  # @return [MachO::FatFile] if the file is a Fat file
  # @raise [ArgumentError] if the given file does not exist
  # @raise [MachO::TruncatedFileError] if the file is too small to have a valid header
  # @raise [MachO::MagicError] if the file's magic is not valid Mach-O magic
  def self.open(filename)
    raise ArgumentError, "#{filename}: no such file" unless File.file?(filename)
    raise TruncatedFileError unless File.stat(filename).size >= 4

    magic = File.open(filename, "rb") { |f| f.read(4) }.unpack("N").first

    if Utils.fat_magic?(magic)
      file = FatFile.new(filename)
    elsif Utils.magic?(magic)
      file = MachOFile.new(filename)
    else
      raise MagicError, magic
    end

    file
  end
end
