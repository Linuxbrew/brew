module UnpackStrategy
  # length of the longest regex (currently Tar)
  MAX_MAGIC_NUMBER_LENGTH = 262
  private_constant :MAX_MAGIC_NUMBER_LENGTH

  def self.strategies
    @strategies ||= [
      Jar,
      LuaRock,
      MicrosoftOfficeXml,
      Zip,
      Xar,
      Compress,
      Tar,
      Gzip,
      Bzip2,
      Xz,
      Lzip,
      Git,
      Mercurial,
      Subversion,
      Cvs,
      Fossil,
      Bazaar,
      P7Zip,
      Rar,
      Lha,
    ].freeze
  end
  private_class_method :strategies

  def self.detect(path, ref_type: nil, ref: nil)
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
end

require "unpack_strategy/bazaar"
require "unpack_strategy/bzip2"
require "unpack_strategy/compress"
require "unpack_strategy/cvs"
require "unpack_strategy/directory"
require "unpack_strategy/fossil"
require "unpack_strategy/git"
require "unpack_strategy/gzip"
require "unpack_strategy/jar"
require "unpack_strategy/lha"
require "unpack_strategy/lua_rock"
require "unpack_strategy/lzip"
require "unpack_strategy/mercurial"
require "unpack_strategy/microsoft_office_xml"
require "unpack_strategy/p7zip"
require "unpack_strategy/rar"
require "unpack_strategy/subversion"
require "unpack_strategy/tar"
require "unpack_strategy/uncompressed"
require "unpack_strategy/xar"
require "unpack_strategy/xz"
require "unpack_strategy/zip"
