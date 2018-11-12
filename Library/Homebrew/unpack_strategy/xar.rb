module UnpackStrategy
  class Xar
    include UnpackStrategy

    using Magic

    def self.extensions
      [".xar"]
    end

    def self.can_extract?(path)
      path.magic_number.match?(/\Axar!/n)
    end

    private

    def extract_to_dir(unpack_dir, basename:, verbose:)
      system_command! "xar",
                      args:    ["-x", "-f", path, "-C", unpack_dir],
                      verbose: verbose
    end
  end
end
