require_relative "shared_examples/invalid_option"

describe Cask::Cmd::Outdated, :cask do
  let(:installed) do
    [
      Cask::CaskLoader.load(cask_path("basic-cask")),
      Cask::CaskLoader.load(cask_path("outdated/local-caffeine")),
      Cask::CaskLoader.load(cask_path("outdated/local-transmission")),
      Cask::CaskLoader.load(cask_path("version-latest-string")),
      Cask::CaskLoader.load(cask_path("outdated/auto-updates")),
    ]
  end

  before do
    installed.each { |cask| InstallHelper.install_with_caskfile(cask) }

    allow_any_instance_of(described_class).to receive(:verbose?).and_return(true)
  end

  it_behaves_like "a command that handles invalid options"

  describe 'without --greedy it ignores the Casks with "vesion latest" or "auto_updates true"' do
    it "checks all the installed Casks when no token is provided" do
      expect {
        described_class.run
      }.to output(<<~EOS).to_stdout
        local-caffeine (1.2.2) != 1.2.3
        local-transmission (2.60) != 2.61
      EOS
    end

    it "checks only the tokens specified in the command line" do
      expect {
        described_class.run("local-caffeine")
      }.to output(<<~EOS).to_stdout
        local-caffeine (1.2.2) != 1.2.3
      EOS
    end

    it 'ignores "auto_updates" and "latest" Casks even when their tokens are provided in the command line' do
      expect {
        described_class.run("local-caffeine", "auto-updates", "version-latest-string")
      }.to output(<<~EOS).to_stdout
        local-caffeine (1.2.2) != 1.2.3
      EOS
    end
  end

  describe "--quiet overrides --verbose" do
    before do
      allow_any_instance_of(described_class).to receive(:verbose?).and_call_original
    end

    it "lists only the names (no versions) of the outdated Casks with --quiet" do
      expect {
        described_class.run("--verbose", "--quiet")
      }.to output(<<~EOS).to_stdout
        local-caffeine
        local-transmission
      EOS
    end
  end

  describe "with --greedy it checks additional Casks" do
    it 'includes the Casks with "auto_updates true" or "version latest" with --greedy' do
      expect {
        described_class.run("--greedy")
      }.to output(<<~EOS).to_stdout
        auto-updates (2.57) != 2.61
        local-caffeine (1.2.2) != 1.2.3
        local-transmission (2.60) != 2.61
        version-latest-string (latest) != latest
      EOS
    end

    it 'does not include the Casks with "auto_updates true" when the version did not change' do
      cask = Cask::CaskLoader.load(cask_path("auto-updates"))
      InstallHelper.install_with_caskfile(cask)

      expect {
        described_class.run("--greedy")
      }.to output(<<~EOS).to_stdout
        local-caffeine (1.2.2) != 1.2.3
        local-transmission (2.60) != 2.61
        version-latest-string (latest) != latest
      EOS
    end
  end
end
