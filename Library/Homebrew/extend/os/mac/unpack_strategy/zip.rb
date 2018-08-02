module UnpackStrategy
  class Zip
    def extract_to_dir(unpack_dir, basename:, verbose:)
      # `ditto` keeps Finder attributes intact and does not skip volume labels
      # like `unzip` does, which can prevent disk images from being unzipped.
      system_command! "ditto", args: ["-x", "-k", path, unpack_dir]
    end
  end
end
