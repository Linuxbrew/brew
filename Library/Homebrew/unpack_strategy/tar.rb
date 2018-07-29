module UnpackStrategy
  class Tar
    include UnpackStrategy

    using Magic

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
      system_command! "tar", args: ["xf", path, "-C", unpack_dir]
    end
  end
end
