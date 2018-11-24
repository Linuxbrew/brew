module UnpackStrategy
  class Pax
    include UnpackStrategy

    using Magic

    def self.extensions
      [".pax"]
    end

    def self.can_extract?(_path)
      false
    end

    private

    def extract_to_dir(unpack_dir, basename:, verbose:)
      system_command! "pax",
                      args:    ["-rf", path],
                      chdir:   unpack_dir,
                      verbose: verbose
    end
  end
end
