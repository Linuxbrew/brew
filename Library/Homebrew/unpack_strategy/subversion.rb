require_relative "directory"

def svn_escape(svn_path)
  # subversion uses '@' to point to a specific revision
  # so when the path contains a @, it requires an additional @ at the end
  # but this is not consistent through all commands
  # the commands are affected as follows:
  #   svn checkout url1 foo@a   # properly checks out url1 to foo@a
  #   svn switch url2 foo@a     # properly switchs foo@a to url2
  #   svn update foo@a@         # properly updates foo@a
  #   svn info foo@a@           # properly obtains info on foo@a
  #   svn export foo@a@ newdir  # properly export foo@a contents to newdir
  result = svn_path.to_s.dup
  result << "@" if result.include? "@"
  result
end

module UnpackStrategy
  class Subversion < Directory
    def self.can_extract?(path:, magic_number:)
      super && (path/".svn").directory?
    end

    private

    def extract_to_dir(unpack_dir, basename:, verbose:)
      system_command! "svn", args: ["export", "--force", svn_escape(path), unpack_dir]
    end
  end
end
