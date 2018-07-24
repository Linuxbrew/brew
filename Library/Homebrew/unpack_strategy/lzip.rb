module UnpackStrategy
  class Lzip
    include UnpackStrategy

    def self.can_extract?(path:, magic_number:)
      magic_number.match?(/\ALZIP/n)
    end

    def dependencies
      @dependencies ||= [Formula["lzip"]]
    end

    private

    def extract_to_dir(unpack_dir, basename:, verbose:)
      FileUtils.cp path, unpack_dir/basename, preserve: true
      quiet_flags = verbose ? [] : ["-q"]
      system_command! "lzip",
                      args: ["-d", *quiet_flags, unpack_dir/basename],
                      env: { "PATH" => PATH.new(Formula["lzip"].opt_bin, ENV["PATH"]) }
    end
  end
end
