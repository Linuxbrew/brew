require "#{File.dirname(__FILE__)}/macho/structure"
require "#{File.dirname(__FILE__)}/macho/view"
require "#{File.dirname(__FILE__)}/macho/headers"
require "#{File.dirname(__FILE__)}/macho/load_commands"
require "#{File.dirname(__FILE__)}/macho/sections"
require "#{File.dirname(__FILE__)}/macho/macho_file"
require "#{File.dirname(__FILE__)}/macho/fat_file"
require "#{File.dirname(__FILE__)}/macho/exceptions"
require "#{File.dirname(__FILE__)}/macho/utils"
require "#{File.dirname(__FILE__)}/macho/tools"

# The primary namespace for ruby-macho.
module MachO
  # release version
  VERSION = "1.1.0".freeze

  # Opens the given filename as a MachOFile or FatFile, depending on its magic.
  # @param filename [String] the file being opened
  # @return [MachOFile] if the file is a Mach-O
  # @return [FatFile] if the file is a Fat file
  # @raise [ArgumentError] if the given file does not exist
  # @raise [TruncatedFileError] if the file is too small to have a valid header
  # @raise [MagicError] if the file's magic is not valid Mach-O magic
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
