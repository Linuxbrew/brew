module UnpackStrategy
  class Xz
    include UnpackStrategy

    def self.can_extract?(path:, magic_number:)
      magic_number.match?(/\A\xFD7zXZ\x00/n)
    end

    def dependencies
      @dependencies ||= [Formula["xz"]]
    end

    private

    def extract_to_dir(unpack_dir, basename:, verbose:)
      FileUtils.cp path, unpack_dir/basename, preserve: true
      quiet_flags = verbose ? [] : ["-q"]
      system_command! "unxz",
                      args: [*quiet_flags, "-T0", "--", unpack_dir/basename],
                      env: { "PATH" => PATH.new(Formula["xz"].opt_bin, ENV["PATH"]) }
      extract_nested_tar(unpack_dir)
    end

    def extract_nested_tar(unpack_dir)
      return unless DependencyCollector.tar_needs_xz_dependency?
      return if (children = unpack_dir.children).count != 1
      return if (tar = children.first).extname != ".tar"

      Dir.mktmpdir do |tmpdir|
        tmpdir = Pathname(tmpdir)
        FileUtils.mv tar, tmpdir/tar.basename
        Tar.new(tmpdir/tar.basename).extract(to: unpack_dir)
      end
    end
  end
end
