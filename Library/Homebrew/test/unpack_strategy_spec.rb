describe UnpackStrategy do
  describe "#extract_nestedly" do
    subject(:strategy) { described_class.detect(path) }

    let(:unpack_dir) { mktmpdir }

    context "when extracting a GZIP nested in a BZIP2" do
      let(:file_name) { "file" }
      let(:path) {
        dir = mktmpdir

        (dir/"file").write "This file was inside a GZIP inside a BZIP2."
        system "gzip", dir.children.first
        system "bzip2", dir.children.first

        dir.children.first
      }

      it "can extract nested archives" do
        strategy.extract_nestedly(to: unpack_dir)

        expect(File.read(unpack_dir/file_name)).to eq("This file was inside a GZIP inside a BZIP2.")
      end
    end

    context "when extracting a directory with nested directories" do
      let(:directories) { "A/B/C" }
      let(:path) {
        (mktmpdir/"file.tar").tap do |path|
          mktmpdir do |dir|
            (dir/directories).mkpath
            system "tar", "-c", "-f", path, "-C", dir, "A/"
          end
        end
      }

      it "does not recurse into nested directories" do
        strategy.extract_nestedly(to: unpack_dir)
        expect(Pathname.glob(unpack_dir/"**/*")).to include unpack_dir/directories
      end
    end

    context "when extracting a nested archive" do
      let(:basename) { "file.xyz" }
      let(:path) {
        (mktmpdir/basename).tap do |path|
          mktmpdir do |dir|
            FileUtils.touch dir/"file.txt"
            system "tar", "-c", "-f", path, "-C", dir, "file.txt"
          end
        end
      }

      it "does not pass down the basename of the archive" do
        strategy.extract_nestedly(to: unpack_dir, basename: basename)
        expect(unpack_dir/"file.txt").to be_a_file
      end
    end
  end
end
