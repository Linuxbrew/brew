require "utils/analytics"
require "formula_installer"

describe Utils::Analytics do
  describe "::os_prefix_ci" do
    context "when os_prefix_ci is not set" do
      before do
        described_class.clear_os_prefix_ci
      end

      it "returns OS_VERSION and prefix when HOMEBREW_PREFIX is a custom prefix" do
        stub_const("HOMEBREW_PREFIX", "blah")
        expect(described_class.os_prefix_ci).to include("#{OS_VERSION}, #{described_class.custom_prefix_label}")
      end

      it "includes CI when ENV['CI'] is set" do
        ENV["CI"] = "true"
        expect(described_class.os_prefix_ci).to include("CI")
      end

      it "does not include prefix when HOMEBREW_PREFIX is the default prefix" do
        stub_const("HOMEBREW_PREFIX", Homebrew::DEFAULT_PREFIX)
        expect(described_class.os_prefix_ci).not_to include(described_class.custom_prefix_label)
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
        ENV.delete("HOMEBREW_NO_ANALYTICS_THIS_RUN")
        ENV.delete("HOMEBREW_NO_ANALYTICS")
        ENV["HOMEBREW_ANALYTICS_DEBUG"] = "true"
        expect(described_class.report_event("install", action)).to be_nil
      end
    end
  end

  describe "::report_build_error" do
    context "when tap is installed" do
      let(:err) { BuildError.new(f, "badprg", %w[arg1 arg2], {}) }
      let(:f) { formula { url "foo-1.0" } }

      it "reports event if BuildError raised for a formula with a public remote repository" do
        allow_any_instance_of(Tap).to receive(:custom_remote?).and_return(false)
        expect(described_class).to respond_to(:report_event)
        described_class.report_build_error(err)
      end

      it "does not report event if BuildError raised for a formula with a private remote repository" do
        expect(described_class.report_build_error(err)).to be_nil
      end
    end

    context "when formula does not have a tap" do
      let(:err) { BuildError.new(f, "badprg", %w[arg1 arg2], {}) }
      let(:f) { double(Formula, name: "foo", path: "blah", tap: nil) }

      it "does not report event if BuildError is raised" do
        expect(described_class.report_build_error(err)).to be_nil
      end
    end

    context "when tap for a formula is not installed" do
      let(:err) { BuildError.new(f, "badprg", %w[arg1 arg2], {}) }
      let(:f) { double(Formula, name: "foo", path: "blah", tap: CoreTap.instance) }

      it "does not report event if BuildError is raised" do
        allow_any_instance_of(Pathname).to receive(:directory?).and_return(false)
        expect(described_class.report_build_error(err)).to be_nil
      end
    end
  end
end
