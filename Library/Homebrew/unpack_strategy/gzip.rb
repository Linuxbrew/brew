module UnpackStrategy
  class Gzip
    include UnpackStrategy

    using Magic

    def self.extensions
      [".gz"]
    end

    def self.can_extract?(path)
      path.magic_number.match?(/\A\037\213/n)
    end

    private

    def extract_to_dir(unpack_dir, basename:, verbose:)
      FileUtils.cp path, unpack_dir/basename, preserve: true
      quiet_flags = verbose ? [] : ["-q"]
      system_command! "gunzip",
                      args:    [*quiet_flags, "-N", "--", unpack_dir/basename],
                      verbose: verbose
    end
  end
end
