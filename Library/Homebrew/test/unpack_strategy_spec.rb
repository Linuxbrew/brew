require "unpack_strategy"

RSpec.shared_examples "UnpackStrategy::detect" do
  it "is correctly detected" do
    expect(UnpackStrategy.detect(path)).to be_a described_class
  end
end

RSpec.shared_examples "#extract" do |children: []|
  specify "#extract" do
    mktmpdir do |unpack_dir|
      described_class.new(path).extract(to: unpack_dir)
      expect(unpack_dir.children(false).map(&:to_s)).to match_array children
    end
  end
end

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
  end
end

describe UncompressedUnpackStrategy do
  let(:path) {
    (mktmpdir/"test").tap do |path|
      FileUtils.touch path
    end
  }

  include_examples "UnpackStrategy::detect"
end

describe P7ZipUnpackStrategy do
  let(:path) { TEST_FIXTURE_DIR/"cask/container.7z" }

  include_examples "UnpackStrategy::detect"
end

describe XarUnpackStrategy, :needs_macos do
  let(:path) { TEST_FIXTURE_DIR/"cask/container.xar" }

  include_examples "UnpackStrategy::detect"
  include_examples "#extract", children: ["container"]
end

describe XzUnpackStrategy do
  let(:path) { TEST_FIXTURE_DIR/"cask/container.xz" }

  include_examples "UnpackStrategy::detect"
end

describe RarUnpackStrategy do
  let(:path) { TEST_FIXTURE_DIR/"cask/container.rar" }

  include_examples "UnpackStrategy::detect"
end

describe LzipUnpackStrategy do
  let(:path) { TEST_FIXTURE_DIR/"test.lz" }

  include_examples "UnpackStrategy::detect"
end

describe LhaUnpackStrategy do
  let(:path) { TEST_FIXTURE_DIR/"test.lha" }

  include_examples "UnpackStrategy::detect"
end

describe JarUnpackStrategy do
  let(:path) { TEST_FIXTURE_DIR/"test.jar" }

  include_examples "UnpackStrategy::detect"
  include_examples "#extract", children: ["test.jar"]
end

describe ZipUnpackStrategy do
  let(:path) { TEST_FIXTURE_DIR/"cask/MyFancyApp.zip" }

  include_examples "UnpackStrategy::detect"
  include_examples "#extract", children: ["MyFancyApp"]

  context "when ZIP archive is corrupted" do
    let(:path) {
      (mktmpdir/"test.zip").tap do |path|
        FileUtils.touch path
      end
    }

    include_examples "UnpackStrategy::detect"
  end
end

describe GzipUnpackStrategy do
  let(:path) { TEST_FIXTURE_DIR/"cask/container.gz" }

  include_examples "UnpackStrategy::detect"
  include_examples "#extract", children: ["container"]
end

describe Bzip2UnpackStrategy do
  let(:path) { TEST_FIXTURE_DIR/"cask/container.bz2" }

  include_examples "UnpackStrategy::detect"
  include_examples "#extract", children: ["container"]
end

describe TarUnpackStrategy do
  let(:path) { TEST_FIXTURE_DIR/"cask/container.tar.gz" }

  include_examples "UnpackStrategy::detect"
  include_examples "#extract", children: ["container"]

  context "when TAR archive is corrupted" do
    let(:path) {
      (mktmpdir/"test.tar").tap do |path|
        FileUtils.touch path
      end
    }

    include_examples "UnpackStrategy::detect"
  end
end

describe GitUnpackStrategy do
  let(:repo) {
    mktmpdir.tap do |repo|
      system "git", "-C", repo, "init"

      FileUtils.touch repo/"test"
      system "git", "-C", repo, "add", "test"
      system "git", "-C", repo, "commit", "-m", "Add `test` file."
    end
  }
  let(:path) { repo }

  include_examples "UnpackStrategy::detect"
  include_examples "#extract", children: [".git", "test"]
end

describe SubversionUnpackStrategy do
  let(:repo) {
    mktmpdir.tap do |repo|
      system "svnadmin", "create", repo
    end
  }
  let(:working_copy) {
    mktmpdir.tap do |working_copy|
      system "svn", "checkout", "file://#{repo}", working_copy

      FileUtils.touch working_copy/"test"
      system "svn", "add", working_copy/"test"
      system "svn", "commit", working_copy, "-m", "Add `test` file."
    end
  }
  let(:path) { working_copy }

  include_examples "UnpackStrategy::detect"
  include_examples "#extract", children: ["test"]
end

describe CvsUnpackStrategy do
  let(:repo) {
    mktmpdir.tap do |repo|
      FileUtils.touch repo/"test"
      (repo/"CVS").mkpath
    end
  }
  let(:path) { repo }

  include_examples "UnpackStrategy::detect"
  include_examples "#extract", children: ["CVS", "test"]
end

describe BazaarUnpackStrategy do
  let(:repo) {
    mktmpdir.tap do |repo|
      FileUtils.touch repo/"test"
      (repo/".bzr").mkpath
    end
  }
  let(:path) { repo }

  include_examples "UnpackStrategy::detect"
  include_examples "#extract", children: ["test"]
end

describe MercurialUnpackStrategy do
  let(:repo) {
    mktmpdir.tap do |repo|
      (repo/".hg").mkpath
    end
  }
  let(:path) { repo }

  include_examples "UnpackStrategy::detect"
end
