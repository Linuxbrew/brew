module UnpackStrategy
  # length of the longest regex (currently Tar)
  MAX_MAGIC_NUMBER_LENGTH = 262
  private_constant :MAX_MAGIC_NUMBER_LENGTH

  def self.strategies
    @strategies ||= [
      Pkg,
      Ttf,
      Otf,
      Air,
      Executable,
      Diff,
      Jar, # needs to be before Zip
      LuaRock, # needs to be before Zip
      MicrosoftOfficeXml, # needs to be before Zip
      Zip,
      Xar,
      Compress,
      Tar, # needs to be before Bzip2/Gzip/Xz/Lzma
      Gzip,
      Lzma,
      Xz,
      Lzip,
      Git,
      Mercurial,
      Subversion,
      Cvs,
      Dmg, # needs to be before Bzip2
      Bzip2,
      Fossil,
      Bazaar,
      SelfExtractingExecutable, # needs to be before Cab
      Cab,
      P7Zip,
      Sit,
      Rar,
      Lha,
    ].freeze
  end
  private_class_method :strategies

  def self.from_type(type)
    type = {
      naked: :uncompressed,
      seven_zip: :p7zip,
    }.fetch(type, type)

    begin
      const_get(type.to_s.split("_").map(&:capitalize).join)
    rescue NameError
      nil
    end
  end

  def self.from_path(path)
    magic_number = if path.directory?
      ""
    else
      File.binread(path, MAX_MAGIC_NUMBER_LENGTH) || ""
    end

    strategy = strategies.detect do |s|
      s.can_extract?(path: path, magic_number: magic_number)
    end

    # This is so that bad files produce good error messages.
    strategy ||= case path.extname
    when ".tar", ".tar.gz", ".tgz", ".tar.bz2", ".tbz", ".tar.xz", ".txz"
      Tar
    when ".zip"
      Zip
    else
      Uncompressed
    end

    strategy
  end

  def self.detect(path, type: nil, ref_type: nil, ref: nil)
    strategy = type ? from_type(type) : from_path(path)
    strategy.new(path, ref_type: ref_type, ref: ref)
  end

  attr_reader :path

  def initialize(path, ref_type: nil, ref: nil)
    @path = Pathname(path).expand_path
    @ref_type = ref_type
    @ref = ref
  end

  def extract(to: nil, basename: nil, verbose: false)
    basename ||= path.basename
    unpack_dir = Pathname(to || Dir.pwd).expand_path
    unpack_dir.mkpath
    extract_to_dir(unpack_dir, basename: basename, verbose: verbose)
  end

  def extract_nestedly(to: nil, basename: nil, verbose: false)
    Dir.mktmpdir do |tmp_unpack_dir|
      tmp_unpack_dir = Pathname(tmp_unpack_dir)

      extract(to: tmp_unpack_dir, basename: basename, verbose: verbose)

      children = tmp_unpack_dir.children

      if children.count == 1 && !children.first.directory?
        s = UnpackStrategy.detect(children.first)

        s.extract_nestedly(to: to, verbose: verbose)
        next
      end

      Directory.new(tmp_unpack_dir).extract(to: to, verbose: verbose)
    end
  end

  def dependencies
    []
  end
end

require "unpack_strategy/air"
require "unpack_strategy/bazaar"
require "unpack_strategy/bzip2"
require "unpack_strategy/cab"
require "unpack_strategy/compress"
require "unpack_strategy/cvs"
require "unpack_strategy/diff"
require "unpack_strategy/directory"
require "unpack_strategy/dmg"
require "unpack_strategy/executable"
require "unpack_strategy/fossil"
require "unpack_strategy/generic_unar"
require "unpack_strategy/git"
require "unpack_strategy/gzip"
require "unpack_strategy/jar"
require "unpack_strategy/lha"
require "unpack_strategy/lua_rock"
require "unpack_strategy/lzip"
require "unpack_strategy/lzma"
require "unpack_strategy/mercurial"
require "unpack_strategy/microsoft_office_xml"
require "unpack_strategy/otf"
require "unpack_strategy/p7zip"
require "unpack_strategy/pkg"
require "unpack_strategy/rar"
require "unpack_strategy/self_extracting_executable"
require "unpack_strategy/sit"
require "unpack_strategy/subversion"
require "unpack_strategy/tar"
require "unpack_strategy/ttf"
require "unpack_strategy/uncompressed"
require "unpack_strategy/xar"
require "unpack_strategy/xz"
require "unpack_strategy/zip"
