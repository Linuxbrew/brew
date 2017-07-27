require "utils/analytics"
require "formula_installer"

describe Utils::Analytics do
  describe "::os_prefix_ci" do
    context "when anonymous_os_prefix_ci is not set" do
      before(:each) do
        if described_class.instance_variable_defined?(:@anonymous_os_prefix_ci)
          described_class.send(:remove_instance_variable, :@anonymous_os_prefix_ci)
        end
      end

      it "returns OS_VERSION and prefix when HOMEBREW_PREFIX is not /usr/local" do
        stub_const("HOMEBREW_PREFIX", "blah")
        expect(described_class.os_prefix_ci).to include("#{OS_VERSION}, non-/usr/local")
      end

      it "includes CI when ENV['CI'] is set" do
        ENV["CI"] = "true"
        expect(described_class.os_prefix_ci).to include("CI")
      end

      it "does not include prefix when HOMEBREW_PREFIX is usr/local" do
        stub_const("HOMEBREW_PREFIX", "/usr/local")
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

  describe "::report_event" do
    let(:f) { formula { url "foo-1.0" } }
    let(:options) { FormulaInstaller.new(f).display_options(f) }
    let(:action)  { "#{f.full_name} #{options}".strip }

    context "when ENV vars is set" do
      it "returns nil when HOMEBREW_NO_ANALYTICS is true" do
        ENV["HOMEBREW_NO_ANALYTICS"] = "true"
        expect(described_class.report_event("install", action)).to be_nil
      end

      it "returns nil when HOMEBREW_NO_ANALYTICS_THIS_RUN is true" do
        ENV["HOMEBREW_NO_ANALYTICS_THIS_RUN"] = "true"
        expect(described_class.report_event("install", action)).to be_nil
      end

      it "returns nil when HOMEBREW_ANALYTICS_DEBUG is true" do
        ENV["HOMEBREW_NO_ANALYTICS_THIS_RUN"] = nil
        ENV["HOMEBREW_NO_ANALYTICS"] = nil
        ENV["HOMEBREW_ANALYTICS_DEBUG"] = "true"
        expect(described_class.report_event("install", action)).to be_nil
      end
    end

    context "when ENV vars are nil" do
      before do
        ENV["HOMEBREW_NO_ANALYTICS"] = nil
        ENV["HOMEBREW_NO_ANALYTICS_THIS_RUN"] = nil
      end

      it "returns nil when HOMEBREW_ANALYTICS_DEBUG is not set" do
        expect(described_class.report_event("install", action)).to be_an_instance_of(Thread)
      end
    end
  end
end
