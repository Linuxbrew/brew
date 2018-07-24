module UnpackStrategy
  class Lha
    include UnpackStrategy

    using Magic

    def self.extensions
      [".lha", ".lzh"]
    end

    def self.can_extract?(path)
      path.magic_number.match?(/\A..-(lh0|lh1|lz4|lz5|lzs|lh\\40|lhd|lh2|lh3|lh4|lh5)-/n)
    end

    def dependencies
      @dependencies ||= [Formula["lha"]]
    end

    private

    def extract_to_dir(unpack_dir, basename:, verbose:)
      system_command! "lha",
                      args: ["xq2w=#{unpack_dir}", path],
                      env: { "PATH" => PATH.new(Formula["lha"].opt_bin, ENV["PATH"]) },
                      verbose: verbose
    end
  end
end
