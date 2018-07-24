require_relative "directory"

module UnpackStrategy
  class Mercurial < Directory
    def self.can_extract?(path:, magic_number:)
      super && (path/".hg").directory?
    end

    private

    def extract_to_dir(unpack_dir, basename:, verbose:)
      system_command! "hg",
                      args: ["--cwd", path, "archive", "--subrepos", "-y", "-t", "files", unpack_dir],
                      env: { "PATH" => PATH.new(Formula["mercurial"].opt_bin, ENV["PATH"]) }
    end
  end
end
