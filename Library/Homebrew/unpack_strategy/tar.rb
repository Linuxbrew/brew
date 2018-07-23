module UnpackStrategy
  class Tar
    include UnpackStrategy

    def self.can_extract?(path:, magic_number:)
      return true if magic_number.match?(/\A.{257}ustar/n)

      # Check if `tar` can list the contents, then it can also extract it.
      IO.popen(["tar", "tf", path], err: File::NULL) do |stdout|
        !stdout.read(1).nil?
      end
    end

    private

    def extract_to_dir(unpack_dir, basename:, verbose:)
      safe_system "tar", "xf", path, "-C", unpack_dir
    end
  end
end
