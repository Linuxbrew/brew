require "requirements/osxfuse_requirement"

describe OsxfuseRequirement do
  subject { described_class.new([]) }

  describe "::binary_osxfuse_installed?" do
    it "returns false if fuse.h does not exist" do
      allow(File).to receive(:exist?).and_return(false)
      expect(described_class).not_to be_binary_osxfuse_installed
    end

    it "returns false if osxfuse include directory is a symlink" do
      allow(File).to receive(:exist?).and_return(true)
      allow(File).to receive(:symlink?).and_return(true)
      expect(described_class).not_to be_binary_osxfuse_installed
    end
  end

  describe "environment" do
    it "adds the fuse directories to the appropriate paths" do
      expect(ENV).to receive(:append_path).with("PKG_CONFIG_PATH", any_args)
      expect(ENV).to receive(:append_path).with("HOMEBREW_LIBRARY_PATHS", any_args)
      expect(ENV).to receive(:append_path).with("HOMEBREW_INCLUDE_PATHS", any_args)
      subject.modify_build_environment
    end
  end
end

describe NonBinaryOsxfuseRequirement do
  subject { described_class.new([]) }

  describe "#message" do
    msg = /osxfuse is already installed from the binary distribution/
    its(:message) { is_expected.to match(msg) }
  end
end
