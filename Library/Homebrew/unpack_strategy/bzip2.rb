module UnpackStrategy
  class Bzip2
    include UnpackStrategy

    def self.can_extract?(path:, magic_number:)
      magic_number.match?(/\ABZh/n)
    end

    private

    def extract_to_dir(unpack_dir, basename:, verbose:)
      FileUtils.cp path, unpack_dir/basename, preserve: true
      quiet_flags = verbose ? [] : ["-q"]
      safe_system "bunzip2", *quiet_flags, unpack_dir/basename
    end
  end
end
