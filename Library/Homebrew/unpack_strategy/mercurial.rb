require_relative "directory"

module UnpackStrategy
  class Mercurial < Directory
    using Magic

    def self.can_extract?(path)
      super && (path/".hg").directory?
    end

    private

    def extract_to_dir(unpack_dir, basename:, verbose:)
      system_command! "hg",
                      args:    ["--cwd", path, "archive", "--subrepos", "-y", "-t", "files", unpack_dir],
                      env:     { "PATH" => PATH.new(Formula["mercurial"].opt_bin, ENV["PATH"]) },
                      verbose: verbose
    end
  end
end
