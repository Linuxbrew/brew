module UnpackStrategy
  class Lha
    include UnpackStrategy

    def self.can_extract?(path:, magic_number:)
      magic_number.match?(/\A..-(lh0|lh1|lz4|lz5|lzs|lh\\40|lhd|lh2|lh3|lh4|lh5)-/n)
    end

    def dependencies
      @dependencies ||= [Formula["lha"]]
    end

    private

    def extract_to_dir(unpack_dir, basename:, verbose:)
      safe_system Formula["lha"].opt_bin/"lha", "xq2w=#{unpack_dir}", path
    end
  end
end
