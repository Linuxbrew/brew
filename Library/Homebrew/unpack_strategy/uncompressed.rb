module UnpackStrategy
  class Uncompressed
    include UnpackStrategy

    alias extract_nestedly extract

    private

    def extract_to_dir(unpack_dir, basename:, verbose:)
      FileUtils.cp path, unpack_dir/basename, preserve: true, verbose: verbose
    end
  end
end
