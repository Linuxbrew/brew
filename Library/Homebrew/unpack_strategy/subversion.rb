require_relative "directory"

module UnpackStrategy
  class Subversion < Directory
    def self.can_extract?(path:, magic_number:)
      super && (path/".svn").directory?
    end

    private

    def extract_to_dir(unpack_dir, basename:, verbose:)
      path_export = path.to_s
      path_export << "@" if path_export.include? "@"
      system_command! "svn", args: ["export", "--force", path_export, unpack_dir]
    end
  end
end
