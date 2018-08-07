module UnpackStrategy
  class Uncompressed
    include UnpackStrategy

    def extract_nestedly(extension_only: false, **options)
      extract(**options)
    end

    private

    def extract_to_dir(unpack_dir, basename:, verbose:)
      FileUtils.cp path, unpack_dir/basename, preserve: true, verbose: verbose
    end
  end
end
