module UnpackStrategy
  class Zip
    prepend Module.new {
      def extract_to_dir(unpack_dir, basename:, verbose:)
        volumes = super.stderr.chomp
                       .split("\n")
                       .map { |l| l[/\A   skipping: (.+)  volume label\Z/, 1] }
                       .compact

        return if volumes.empty?

        Dir.mktmpdir do |tmp_unpack_dir|
          tmp_unpack_dir = Pathname(tmp_unpack_dir)

          # `ditto` keeps Finder attributes intact and does not skip volume labels
          # like `unzip` does, which can prevent disk images from being unzipped.
          system_command! "ditto",
                          args: ["-x", "-k", path, tmp_unpack_dir],
                          verbose: verbose

          volumes.each do |volume|
            FileUtils.mv tmp_unpack_dir/volume, unpack_dir/volume, verbose: verbose
          end
        end
      end
    }
  end
end
