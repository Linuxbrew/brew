require "resource"

describe Resource do
  subject { described_class.new("test") }

  describe "#url" do
    it "sets the URL" do
      subject.url("foo")
      expect(subject.url).to eq("foo")
    end

    it "can set the URL with specifications" do
      subject.url("foo", branch: "master")
      expect(subject.url).to eq("foo")
      expect(subject.specs).to eq(branch: "master")
    end

    it "can set the URL with a custom download strategy class" do
      strategy = Class.new(AbstractDownloadStrategy)
      subject.url("foo", using: strategy)
      expect(subject.url).to eq("foo")
      expect(subject.download_strategy).to eq(strategy)
    end

    it "can set the URL with specifications and a custom download strategy class" do
      strategy = Class.new(AbstractDownloadStrategy)
      subject.url("foo", using: strategy, branch: "master")
      expect(subject.url).to eq("foo")
      expect(subject.specs).to eq(branch: "master")
      expect(subject.download_strategy).to eq(strategy)
    end

    it "can set the URL with a custom download strategy symbol" do
      subject.url("foo", using: :git)
      expect(subject.url).to eq("foo")
      expect(subject.download_strategy).to eq(GitDownloadStrategy)
    end

    it "raises an error if the download strategy class is unkown" do
      expect { subject.url("foo", using: Class.new) }.to raise_error(TypeError)
    end

    it "does not mutate the specifications hash" do
      specs = { using: :git, branch: "master" }
      subject.url("foo", specs)
      expect(subject.specs).to eq(branch: "master")
      expect(subject.using).to eq(:git)
      expect(specs).to eq(using: :git, branch: "master")
    end
  end

  describe "#version" do
    it "sets the version" do
      subject.version("1.0")
      expect(subject.version).to eq(Version.parse("1.0"))
      expect(subject.version).not_to be_detected_from_url
    end

    it "can detect the version from a URL" do
      subject.url("https://example.com/foo-1.0.tar.gz")
      expect(subject.version).to eq(Version.parse("1.0"))
      expect(subject.version).to be_detected_from_url
    end

    it "can set the version with a scheme" do
      klass = Class.new(Version)
      subject.version klass.new("1.0")
      expect(subject.version).to eq(Version.parse("1.0"))
      expect(subject.version).to be_a(klass)
    end

    it "can set the version from a tag" do
      subject.url("https://example.com/foo-1.0.tar.gz", tag: "v1.0.2")
      expect(subject.version).to eq(Version.parse("1.0.2"))
      expect(subject.version).to be_detected_from_url
    end

    it "rejects non-string versions" do
      expect { subject.version(1) }.to raise_error(TypeError)
      expect { subject.version(2.0) }.to raise_error(TypeError)
      expect { subject.version(Object.new) }.to raise_error(TypeError)
    end

    it "returns nil if unset" do
      expect(subject.version).to be nil
    end
  end

  describe "#mirrors" do
    it "is empty by defaults" do
      expect(subject.mirrors).to be_empty
    end

    it "returns an array of mirrors added with #mirror" do
      subject.mirror("foo")
      subject.mirror("bar")
      expect(subject.mirrors).to eq(%w[foo bar])
    end
  end

  describe "#checksum" do
    it "returns nil if unset" do
      expect(subject.checksum).to be nil
    end

    it "returns the checksum set with #sha256" do
      subject.sha256(TEST_SHA256)
      expect(subject.checksum).to eq(Checksum.new(:sha256, TEST_SHA256))
    end
  end

  describe "#download_strategy" do
    it "returns the download strategy" do
      strategy = Object.new
      expect(DownloadStrategyDetector)
        .to receive(:detect).with("foo", nil).and_return(strategy)
      subject.url("foo")
      expect(subject.download_strategy).to eq(strategy)
    end
  end

  describe "#owner" do
    it "sets the owner" do
      owner = Object.new
      subject.owner = owner
      expect(subject.owner).to eq(owner)
    end

    it "sets its owner to be the patches' owner" do
      subject.patch(:p1) { url "file:///my.patch" }
      owner = Object.new
      subject.owner = owner
      subject.patches.each do |p|
        expect(p.resource.owner).to eq(owner)
      end
    end
  end

  describe "#patch" do
    it "adds a patch" do
      subject.patch(:p1, :DATA)
      expect(subject.patches.count).to eq(1)
      expect(subject.patches.first.strip).to eq(:p1)
    end
  end

  specify "#verify_download_integrity_missing" do
    fn = Pathname.new("test")

    allow(fn).to receive(:file?).and_return(true)
    expect(fn).to receive(:verify_checksum).and_raise(ChecksumMissingError)
    expect(fn).to receive(:sha256)

    subject.verify_download_integrity(fn)
  end

  specify "#verify_download_integrity_mismatch" do
    fn = double(file?: true)
    checksum = subject.sha256(TEST_SHA256)

    expect(fn).to receive(:verify_checksum).with(checksum)
      .and_raise(ChecksumMismatchError.new(fn, checksum, Object.new))

    expect {
      subject.verify_download_integrity(fn)
    }.to raise_error(ChecksumMismatchError)
  end
end
