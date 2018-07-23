module UnpackStrategy
  class Rar
    include UnpackStrategy

    def self.can_extract?(path:, magic_number:)
      magic_number.match?(/\ARar!/n)
    end

    def dependencies
      @dependencies ||= [Formula["unrar"]]
    end

    private

    def extract_to_dir(unpack_dir, basename:, verbose:)
      safe_system Formula["unrar"].opt_bin/"unrar", "x", "-inul", path, unpack_dir
    end
  end
end
