require_relative "directory"

module UnpackStrategy
  class Subversion < Directory
    def self.can_extract?(path:, magic_number:)
      super && (path/".svn").directory?
    end

    private

    def extract_to_dir(unpack_dir, basename:, verbose:)
      system_command! "svn", args: ["export", "--force", path, unpack_dir]
    end
  end
end
