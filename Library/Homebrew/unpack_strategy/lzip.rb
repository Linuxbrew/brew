module UnpackStrategy
  class Lzip
    include UnpackStrategy

    using Magic

    def self.extensions
      [".lz"]
    end

    def self.can_extract?(path)
      path.magic_number.match?(/\ALZIP/n)
    end

    def dependencies
      @dependencies ||= [Formula["lzip"]]
    end

    private

    def extract_to_dir(unpack_dir, basename:, verbose:)
      FileUtils.cp path, unpack_dir/basename, preserve: true
      quiet_flags = verbose ? [] : ["-q"]
      system_command! "lzip",
                      args:    ["-d", *quiet_flags, unpack_dir/basename],
                      env:     { "PATH" => PATH.new(Formula["lzip"].opt_bin, ENV["PATH"]) },
                      verbose: verbose
    end
  end
end
