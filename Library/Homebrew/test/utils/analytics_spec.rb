require "utils/analytics"

describe Utils::Analytics do
  describe "::os_prefix_ci" do
    context "when anonymous_os_prefix_ci is not set" do
      it "returns OS_VERSION and prefix when HOMEBREW_PREFIX is not /usr/local" do
        expect(described_class.os_prefix_ci).to include("#{OS_VERSION}, non-/usr/local")
      end

      it "includes CI when ENV['CI'] is set" do
        allow(ENV).to receive(:[]).with("CI").and_return("true")
        expect(described_class.os_prefix_ci).to include("CI")
      end

      it "does not include prefix when HOMEBREW_PREFIX is usr/local" do
        allow(HOMEBREW_PREFIX).to receive(:to_s).and_return("/usr/local")
        expect(described_class.os_prefix_ci).not_to include("non-/usr/local")
      end
    end

    context "when anonymous_os_prefix_ci is set" do
      let(:anonymous_os_prefix_ci) { "macOS 10.11.6, non-/usr/local, CI" }

      it "returns anonymous_os_prefix_ci" do
        described_class.instance_variable_set(:@anonymous_os_prefix_ci, anonymous_os_prefix_ci)
        expect(described_class.os_prefix_ci).to eq(anonymous_os_prefix_ci)
      end
    end
  end

  describe "::" do
    
  end
end