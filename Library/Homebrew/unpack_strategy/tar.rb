module UnpackStrategy
  class Tar
    include UnpackStrategy

    using Magic

    def self.extensions
      [
        ".tar",
        ".tbz", ".tbz2", ".tar.bz2",
        ".tgz", ".tar.gz",
        ".tlzma", ".tar.lzma",
        ".txz", ".tar.xz"
      ]
    end

    def self.can_extract?(path)
      return true if path.magic_number.match?(/\A.{257}ustar/n)

      unless [Bzip2, Gzip, Lzip, Xz].any? { |s| s.can_extract?(path) }
        return false
      end

      # Check if `tar` can list the contents, then it can also extract it.
      IO.popen(["tar", "tf", path], err: File::NULL) do |stdout|
        !stdout.read(1).nil?
      end
    end

    private

    def extract_to_dir(unpack_dir, basename:, verbose:)
      Dir.mktmpdir do |tmpdir|
        tar_path = path

        if DependencyCollector.tar_needs_xz_dependency? && Xz.can_extract?(path)
          tmpdir = Pathname(tmpdir)
          Xz.new(path).extract(to: tmpdir, verbose: verbose)
          tar_path = tmpdir.children.first
        end

        system_command! "tar",
                        args:    ["xf", tar_path, "-C", unpack_dir],
                        verbose: verbose
      end
    end
  end
end
