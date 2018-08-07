module UnpackStrategy
  class P7Zip
    include UnpackStrategy

    using Magic

    def self.extensions
      [".7z"]
    end

    def self.can_extract?(path)
      path.magic_number.match?(/\A7z\xBC\xAF\x27\x1C/n)
    end

    def dependencies
      @dependencies ||= [Formula["p7zip"]]
    end

    private

    def extract_to_dir(unpack_dir, basename:, verbose:)
      system_command! "7zr",
                      args: ["x", "-y", "-bd", "-bso0", path, "-o#{unpack_dir}"],
                      env: { "PATH" => PATH.new(Formula["p7zip"].opt_bin, ENV["PATH"]) },
                      verbose: verbose
    end
  end
end
