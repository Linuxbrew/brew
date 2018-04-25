require "requirements/osxfuse_requirement"

describe OsxfuseRequirement do
  subject(:requirement) { described_class.new([]) }

  describe "::binary_osxfuse_installed?", :needs_macos do
    alias_matcher :have_binary_osxfuse_installed, :be_binary_osxfuse_installed

    it "returns false if fuse.h does not exist" do
      allow(File).to receive(:exist?).and_return(false)
      expect(described_class).not_to have_binary_osxfuse_installed
    end

    it "returns false if osxfuse include directory is a symlink" do
      allow(File).to receive(:exist?).and_return(true)
      allow(File).to receive(:symlink?).and_return(true)
      expect(described_class).not_to have_binary_osxfuse_installed
    end
  end

  describe "#modify_build_environment", :needs_macos do
    it "adds the fuse directories to PKG_CONFIG_PATH" do
      allow(ENV).to receive(:append_path)
      requirement.modify_build_environment
      expect(ENV).to have_received(:append_path).with("PKG_CONFIG_PATH", any_args)
    end

    it "adds the fuse directories to HOMEBREW_LIBRARY_PATHS" do
      allow(ENV).to receive(:append_path)
      requirement.modify_build_environment
      expect(ENV).to have_received(:append_path).with("HOMEBREW_LIBRARY_PATHS", any_args)
    end

    it "adds the fuse directories to HOMEBREW_INCLUDE_PATHS" do
      allow(ENV).to receive(:append_path)
      requirement.modify_build_environment
      expect(ENV).to have_received(:append_path).with("HOMEBREW_INCLUDE_PATHS", any_args)
    end
  end

  describe "#message" do
    it "prompts for installation of 'libfuse' on Linux", :needs_linux do
      expect(requirement.message).to match("libfuse is required to install this formula")
    end

    it "prompts for installation of 'osxFuse' on macOS", :needs_macos do
      expect(requirement.message).to match("osxfuse.github.io")
    end
  end
end
