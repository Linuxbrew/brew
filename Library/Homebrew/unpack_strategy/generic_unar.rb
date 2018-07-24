module UnpackStrategy
  class GenericUnar
    include UnpackStrategy

    def self.can_extract?(path:, magic_number:)
      false
    end

    def dependencies
      @dependencies ||= [Formula["unar"]]
    end

    private

    def extract_to_dir(unpack_dir, basename:, verbose:)
      system_command! "unar",
                      args: ["-force-overwrite", "-quiet", "-no-directory", "-output-directory", unpack_dir, "--", path],
                      env: { "PATH" => PATH.new(Formula["unar"].opt_bin, ENV["PATH"]) }
    end
  end
end
