module UnpackStrategy
  class Rar
    include UnpackStrategy

    using Magic

    def self.extensions
      [".rar"]
    end

    def self.can_extract?(path)
      path.magic_number.match?(/\ARar!/n)
    end

    def dependencies
      @dependencies ||= [Formula["unrar"]]
    end

    private

    def extract_to_dir(unpack_dir, basename:, verbose:)
      system_command! "unrar",
                      args: ["x", "-inul", path, unpack_dir],
                      env: { "PATH" => PATH.new(Formula["unrar"].opt_bin, ENV["PATH"]) },
                      verbose: verbose
    end
  end
end
