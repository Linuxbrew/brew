module UnpackStrategy
  class Zip
    include UnpackStrategy

    def self.can_extract?(path:, magic_number:)
      magic_number.match?(/\APK(\003\004|\005\006)/n)
    end

    private

    def extract_to_dir(unpack_dir, basename:, verbose:)
      quiet_flags = verbose ? [] : ["-qq"]
      system_command! "unzip", args: [*quiet_flags, path, "-d", unpack_dir]
    end
  end
end
