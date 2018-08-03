module UnpackStrategy
  class Cab
    include UnpackStrategy

    using Magic

    def self.extensions
      [".cab"]
    end

    def self.can_extract?(path)
      path.magic_number.match?(/\AMSCF/n)
    end

    def extract_to_dir(unpack_dir, basename:, verbose:)
      system_command! "cabextract",
                      args: ["-d", unpack_dir, "--", path],
                      env: { "PATH" => PATH.new(Formula["cabextract"].opt_bin, ENV["PATH"]) },
                      verbose: verbose
    end

    def dependencies
      @dependencies ||= [Formula["cabextract"]]
    end
  end
end
