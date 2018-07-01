require "unpack_strategy"

describe UnpackStrategy, :focus do
  matcher :be_detected_as_a do |klass|
    match do |expected|
      @detected = described_class.detect(expected)
      @detected.is_a?(klass)
    end

    failure_message do
      <<~EOS
        expected: #{klass}
        detected: #{@detected}
      EOS
    end
  end

  describe "::detect" do
    it "correctly detects JAR files" do
      expect(TEST_FIXTURE_DIR/"test.jar").to be_detected_as_a UncompressedUnpackStrategy
    end

    it "correctly detects ZIP files" do
      expect(TEST_FIXTURE_DIR/"cask/MyFancyApp.zip").to be_detected_as_a ZipUnpackStrategy
    end

    it "correctly detects BZIP2 files" do
      expect(TEST_FIXTURE_DIR/"cask/container.bz2").to be_detected_as_a Bzip2UnpackStrategy
    end

    it "correctly detects GZIP files" do
      expect(TEST_FIXTURE_DIR/"cask/container.gz").to be_detected_as_a GzipUnpackStrategy
    end

    it "correctly detects compressed TAR files" do
      expect(TEST_FIXTURE_DIR/"cask/container.tar.gz").to be_detected_as_a TarUnpackStrategy
    end

    it "correctly detects 7-ZIP files" do
      expect(TEST_FIXTURE_DIR/"cask/container.7z").to be_detected_as_a P7ZipUnpackStrategy
    end

    it "correctly detects XAR files" do
      expect(TEST_FIXTURE_DIR/"cask/container.xar").to be_detected_as_a XarUnpackStrategy
    end

    it "correctly detects XZ files" do
      expect(TEST_FIXTURE_DIR/"cask/container.xz").to be_detected_as_a XzUnpackStrategy
    end

    it "correctly detects RAR files" do
      expect(TEST_FIXTURE_DIR/"cask/container.rar").to be_detected_as_a RarUnpackStrategy
    end

    it "correctly detects LZIP files" do
      expect(TEST_FIXTURE_DIR/"test.lz").to be_detected_as_a LzipUnpackStrategy
    end

    it "correctly detects LHA files" do
      expect(TEST_FIXTURE_DIR/"test.lha").to be_detected_as_a LhaUnpackStrategy
    end

    it "correctly detects Git repositories" do
      mktmpdir do |repo|
        system "git", "-C", repo, "init"

        expect(repo).to be_detected_as_a GitUnpackStrategy
      end
    end

    it "correctly detects Subversion repositories" do
      mktmpdir do |path|
        repo = path/"repo"
        working_copy = path/"working_copy"

        system "svnadmin", "create", repo
        system "svn", "checkout", "file://#{repo}", working_copy

        expect(working_copy).to be_detected_as_a SubversionUnpackStrategy
      end
    end
  end
end

describe GitUnpackStrategy do
  describe "#extract" do
    it "correctly extracts a Subversion repository" do
      mktmpdir do |path|
        repo = path/"repo"

        repo.mkpath

        system "git", "-C", repo, "init"

        FileUtils.touch repo/"test"
        system "git", "-C", repo, "add", "test"
        system "git", "-C", repo, "commit", "-m", "Add `test` file."

        unpack_dir = path/"unpack_dir"
        GitUnpackStrategy.new(repo).extract(to: unpack_dir)
        expect(unpack_dir.children(false).map(&:to_s)).to match_array [".git", "test"]
      end
    end
  end
end

describe SubversionUnpackStrategy do
  describe "#extract" do
    it "correctly extracts a Subversion repository" do
      mktmpdir do |path|
        repo = path/"repo"
        working_copy = path/"working_copy"

        system "svnadmin", "create", repo
        system "svn", "checkout", "file://#{repo}", working_copy

        FileUtils.touch working_copy/"test"
        system "svn", "add", working_copy/"test"
        system "svn", "commit", working_copy, "-m", "Add `test` file."

        unpack_dir = path/"unpack_dir"
        SubversionUnpackStrategy.new(working_copy).extract(to: unpack_dir)
        expect(unpack_dir.children(false).map(&:to_s)).to match_array ["test"]
      end
    end
  end
end
