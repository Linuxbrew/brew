module UnpackStrategy
  class Lzma
    include UnpackStrategy

    def self.can_extract?(path:, magic_number:)
      magic_number.match?(/\A\]\000\000\200\000/n)
    end

    def extract_to_dir(unpack_dir, basename:, verbose:)
      FileUtils.cp path, unpack_dir/basename, preserve: true
      quiet_flags = verbose ? [] : ["-q"]
      system_command! "unlzma",
                      args: [*quiet_flags, "--", unpack_dir/basename],
                      env: { "PATH" => PATH.new(Formula["xz"].opt_bin, ENV["PATH"]) }
    end

    def dependencies
      @dependencies ||= [Formula["xz"]]
    end
  end
end
