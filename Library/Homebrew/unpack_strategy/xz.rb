module UnpackStrategy
  class Xz
    include UnpackStrategy

    using Magic

    def self.extensions
      [".xz"]
    end

    def self.can_extract?(path)
      path.magic_number.match?(/\A\xFD7zXZ\x00/n)
    end

    def dependencies
      @dependencies ||= [Formula["xz"]]
    end

    private

    def extract_to_dir(unpack_dir, basename:, verbose:)
      FileUtils.cp path, unpack_dir/basename, preserve: true
      quiet_flags = verbose ? [] : ["-q"]
      system_command! "unxz",
                      args:    [*quiet_flags, "-T0", "--", unpack_dir/basename],
                      env:     { "PATH" => PATH.new(Formula["xz"].opt_bin, ENV["PATH"]) },
                      verbose: verbose
    end
  end
end
