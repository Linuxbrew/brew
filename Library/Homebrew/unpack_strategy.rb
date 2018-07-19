class UnpackStrategy
  # length of the longest regex (currently TarUnpackStrategy)
  MAX_MAGIC_NUMBER_LENGTH = 262
  private_constant :MAX_MAGIC_NUMBER_LENGTH

  def self.strategies
    @strategies ||= [
      JarUnpackStrategy,
      LuaRockUnpackStrategy,
      MicrosoftOfficeXmlUnpackStrategy,
      ZipUnpackStrategy,
      XarUnpackStrategy,
      CompressUnpackStrategy,
      TarUnpackStrategy,
      GzipUnpackStrategy,
      Bzip2UnpackStrategy,
      XzUnpackStrategy,
      LzipUnpackStrategy,
      GitUnpackStrategy,
      MercurialUnpackStrategy,
      SubversionUnpackStrategy,
      CvsUnpackStrategy,
      FossilUnpackStrategy,
      BazaarUnpackStrategy,
      P7ZipUnpackStrategy,
      RarUnpackStrategy,
      LhaUnpackStrategy,
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
      TarUnpackStrategy
    when ".zip"
      ZipUnpackStrategy
    else
      UncompressedUnpackStrategy
    end

    strategy.new(path, ref_type: ref_type, ref: ref)
  end

  attr_reader :path

  def initialize(path, ref_type: nil, ref: nil)
    @path = Pathname(path).expand_path
    @ref_type = ref_type
    @ref = ref
  end

  def extract(to: nil, basename: nil)
    basename ||= path.basename
    unpack_dir = Pathname(to || Dir.pwd).expand_path
    unpack_dir.mkpath
    extract_to_dir(unpack_dir, basename: basename)
  end

  def extract_nestedly(to: nil, basename: nil)
    Dir.mktmpdir do |tmp_unpack_dir|
      tmp_unpack_dir = Pathname(tmp_unpack_dir)

      extract(to: tmp_unpack_dir, basename: basename)

      children = tmp_unpack_dir.children

      if children.count == 1 && !children.first.directory?
        s = self.class.detect(children.first)

        s.extract_nestedly(to: to)
        next
      end

      DirectoryUnpackStrategy.new(tmp_unpack_dir).extract(to: to)
    end
  end
end

class DirectoryUnpackStrategy < UnpackStrategy
  def self.can_extract?(path:, magic_number:)
    path.directory?
  end

  private

  def extract_to_dir(unpack_dir, basename:)
    FileUtils.cp_r File.join(path, "."), unpack_dir, preserve: true
  end
end

class UncompressedUnpackStrategy < UnpackStrategy
  alias extract_nestedly extract

  private

  def extract_to_dir(unpack_dir, basename:)
    FileUtils.cp path, unpack_dir/basename, preserve: true
  end
end

class MicrosoftOfficeXmlUnpackStrategy < UncompressedUnpackStrategy
  def self.can_extract?(path:, magic_number:)
    return false unless ZipUnpackStrategy.can_extract?(path: path, magic_number: magic_number)

    # Check further if the ZIP is a Microsoft Office XML document.
    magic_number.match?(/\APK\003\004/n) &&
      magic_number.match?(%r{\A.{30}(\[Content_Types\]\.xml|_rels/\.rels)}n)
  end
end

class LuaRockUnpackStrategy < UncompressedUnpackStrategy
  def self.can_extract?(path:, magic_number:)
    return false unless ZipUnpackStrategy.can_extract?(path: path, magic_number: magic_number)

    # Check further if the ZIP is a LuaRocks package.
    out, _, status = Open3.capture3("zipinfo", "-1", path)
    status.success? && out.split("\n").any? { |line| line.match?(%r{\A[^/]+.rockspec\Z}) }
  end
end

class JarUnpackStrategy < UncompressedUnpackStrategy
  def self.can_extract?(path:, magic_number:)
    return false unless ZipUnpackStrategy.can_extract?(path: path, magic_number: magic_number)

    # Check further if the ZIP is a JAR/WAR.
    out, _, status = Open3.capture3("zipinfo", "-1", path)
    status.success? && out.split("\n").include?("META-INF/MANIFEST.MF")
  end
end

class P7ZipUnpackStrategy < UnpackStrategy
  def self.can_extract?(path:, magic_number:)
    magic_number.match?(/\A7z\xBC\xAF\x27\x1C/n)
  end

  private

  def extract_to_dir(unpack_dir, basename:)
    safe_system "7zr", "x", "-y", "-bd", "-bso0", path, "-o#{unpack_dir}"
  end
end

class ZipUnpackStrategy < UnpackStrategy
  def self.can_extract?(path:, magic_number:)
    magic_number.match?(/\APK(\003\004|\005\006)/n)
  end

  private

  def extract_to_dir(unpack_dir, basename:)
    safe_system "unzip", "-qq", path, "-d", unpack_dir
  end
end

class TarUnpackStrategy < UnpackStrategy
  def self.can_extract?(path:, magic_number:)
    return true if magic_number.match?(/\A.{257}ustar/n)

    # Check if `tar` can list the contents, then it can also extract it.
    IO.popen(["tar", "tf", path], err: File::NULL) do |stdout|
      !stdout.read(1).nil?
    end
  end

  private

  def extract_to_dir(unpack_dir, basename:)
    safe_system "tar", "xf", path, "-C", unpack_dir
  end
end

class CompressUnpackStrategy < TarUnpackStrategy
  def self.can_extract?(path:, magic_number:)
    magic_number.match?(/\A\037\235/n)
  end
end

class XzUnpackStrategy < UnpackStrategy
  def self.can_extract?(path:, magic_number:)
    magic_number.match?(/\A\xFD7zXZ\x00/n)
  end

  private

  def extract_to_dir(unpack_dir, basename:)
    super
    safe_system Formula["xz"].opt_bin/"unxz", "-q", "-T0", unpack_dir/basename
    extract_nested_tar(unpack_dir, basename: basename)
  end

  def extract_nested_tar(unpack_dir, basename:)
    return unless DependencyCollector.tar_needs_xz_dependency?
    return if (children = unpack_dir.children).count != 1
    return if (tar = children.first).extname != ".tar"

    Dir.mktmpdir do |tmpdir|
      tmpdir = Pathname(tmpdir)
      FileUtils.mv tar, tmpdir/tar.basename
      TarUnpackStrategy.new(tmpdir/tar.basename).extract(to: unpack_dir, basename: basename)
    end
  end
end

class Bzip2UnpackStrategy < UnpackStrategy
  def self.can_extract?(path:, magic_number:)
    magic_number.match?(/\ABZh/n)
  end

  private

  def extract_to_dir(unpack_dir, basename:)
    FileUtils.cp path, unpack_dir/basename, preserve: true
    safe_system "bunzip2", "-q", unpack_dir/basename
  end
end

class GzipUnpackStrategy < UnpackStrategy
  def self.can_extract?(path:, magic_number:)
    magic_number.match?(/\A\037\213/n)
  end

  private

  def extract_to_dir(unpack_dir, basename:)
    FileUtils.cp path, unpack_dir/basename, preserve: true
    safe_system "gunzip", "-q", "-N", unpack_dir/basename
  end
end

class LzipUnpackStrategy < UnpackStrategy
  def self.can_extract?(path:, magic_number:)
    magic_number.match?(/\ALZIP/n)
  end

  private

  def extract_to_dir(unpack_dir, basename:)
    FileUtils.cp path, unpack_dir/basename, preserve: true
    safe_system Formula["lzip"].opt_bin/"lzip", "-d", "-q", unpack_dir/basename
  end
end

class XarUnpackStrategy < UnpackStrategy
  def self.can_extract?(path:, magic_number:)
    magic_number.match?(/\Axar!/n)
  end

  private

  def extract_to_dir(unpack_dir, basename:)
    safe_system "xar", "-x", "-f", path, "-C", unpack_dir
  end
end

class RarUnpackStrategy < UnpackStrategy
  def self.can_extract?(path:, magic_number:)
    magic_number.match?(/\ARar!/n)
  end

  private

  def extract_to_dir(unpack_dir, basename:)
    safe_system Formula["unrar"].opt_bin/"unrar", "x", "-inul", path, unpack_dir
  end
end

class LhaUnpackStrategy < UnpackStrategy
  def self.can_extract?(path:, magic_number:)
    magic_number.match?(/\A..-(lh0|lh1|lz4|lz5|lzs|lh\\40|lhd|lh2|lh3|lh4|lh5)-/n)
  end

  private

  def extract_to_dir(unpack_dir, basename:)
    safe_system Formula["lha"].opt_bin/"lha", "xq2w=#{unpack_dir}", path
  end
end

class GitUnpackStrategy < DirectoryUnpackStrategy
  def self.can_extract?(path:, magic_number:)
    super && (path/".git").directory?
  end
end

class SubversionUnpackStrategy < DirectoryUnpackStrategy
  def self.can_extract?(path:, magic_number:)
    super && (path/".svn").directory?
  end

  private

  def extract_to_dir(unpack_dir, basename:)
    safe_system "svn", "export", "--force", path, unpack_dir
  end
end

class CvsUnpackStrategy < DirectoryUnpackStrategy
  def self.can_extract?(path:, magic_number:)
    super && (path/"CVS").directory?
  end
end

class MercurialUnpackStrategy < DirectoryUnpackStrategy
  def self.can_extract?(path:, magic_number:)
    super && (path/".hg").directory?
  end

  private

  def extract_to_dir(unpack_dir, basename:)
    with_env "PATH" => PATH.new(Formula["mercurial"].opt_bin, ENV["PATH"]) do
      safe_system "hg", "--cwd", path, "archive", "--subrepos", "-y", "-t", "files", unpack_dir
    end
  end
end

class FossilUnpackStrategy < UnpackStrategy
  def self.can_extract?(path:, magic_number:)
    return false unless magic_number.match?(/\ASQLite format 3\000/n)

    # Fossil database is made up of artifacts, so the `artifact` table must exist.
    query = "select count(*) from sqlite_master where type = 'view' and name = 'artifact'"
    Utils.popen_read("sqlite3", path, query).to_i == 1
  end

  private

  def extract_to_dir(unpack_dir, basename:)
    args = if @ref_type && @ref
      [@ref]
    else
      []
    end

    with_env "PATH" => PATH.new(Formula["fossil"].opt_bin, ENV["PATH"]) do
      safe_system "fossil", "open", path, *args, chdir: unpack_dir
    end
  end
end

class BazaarUnpackStrategy < DirectoryUnpackStrategy
  def self.can_extract?(path:, magic_number:)
    super && (path/".bzr").directory?
  end

  private

  def extract_to_dir(unpack_dir, basename:)
    super

    # The export command doesn't work on checkouts (see https://bugs.launchpad.net/bzr/+bug/897511).
    FileUtils.rm_r unpack_dir/".bzr"
  end
end
