require_relative "directory"

module UnpackStrategy
  class Mercurial < Directory
    def self.can_extract?(path:, magic_number:)
      super && (path/".hg").directory?
    end

    private

    def extract_to_dir(unpack_dir, basename:, verbose:)
      with_env "PATH" => PATH.new(Formula["mercurial"].opt_bin, ENV["PATH"]) do
        safe_system "hg", "--cwd", path, "archive", "--subrepos", "-y", "-t", "files", unpack_dir
      end
    end
  end
end
