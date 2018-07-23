module UnpackStrategy
  class Gzip
    include UnpackStrategy

    def self.can_extract?(path:, magic_number:)
      magic_number.match?(/\A\037\213/n)
    end

    private

    def extract_to_dir(unpack_dir, basename:, verbose:)
      FileUtils.cp path, unpack_dir/basename, preserve: true
      quiet_flags = verbose ? [] : ["-q"]
      safe_system "gunzip", *quiet_flags, "-N", unpack_dir/basename
    end
  end
end
