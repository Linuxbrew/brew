module UnpackStrategy
  class Bzip2
    include UnpackStrategy

    using Magic

    def self.extensions
      [".bz2"]
    end

    def self.can_extract?(path)
      path.magic_number.match?(/\ABZh/n)
    end

    private

    def extract_to_dir(unpack_dir, basename:, verbose:)
      FileUtils.cp path, unpack_dir/basename, preserve: true
      quiet_flags = verbose ? [] : ["-q"]
      system_command! "bunzip2",
                      args: [*quiet_flags, unpack_dir/basename],
                      verbose: verbose
    end
  end
end
