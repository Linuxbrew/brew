require_relative "directory"

module UnpackStrategy
  class Bazaar < Directory
    using Magic

    def self.can_extract?(path)
      super && (path/".bzr").directory?
    end

    private

    def extract_to_dir(unpack_dir, basename:, verbose:)
      super

      # The export command doesn't work on checkouts (see https://bugs.launchpad.net/bzr/+bug/897511).
      FileUtils.rm_r unpack_dir/".bzr"
    end
  end
end
