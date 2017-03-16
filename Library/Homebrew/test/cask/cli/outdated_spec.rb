describe Hbc::CLI::Outdated, :cask do
  let(:installed) do
    [
      Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/basic-cask.rb"),
      Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/outdated/local-caffeine.rb"),
      Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/outdated/local-transmission.rb"),
      Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/version-latest-string.rb"),
      Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/outdated/auto-updates.rb"),
    ]
  end

  before do
    shutup do
      installed.each { |cask| InstallHelper.install_with_caskfile(cask) }
    end
    allow(Hbc::CLI).to receive(:verbose?).and_return(true)
  end

  describe 'without --greedy it ignores the Casks with "vesion latest" or "auto_updates true"' do
    it "checks all the installed Casks when no token is provided" do
      expect {
        Hbc::CLI::Outdated.run
      }.to output(<<-EOS.undent).to_stdout
        local-caffeine (1.2.2) != 1.2.3
        local-transmission (2.60) != 2.61
      EOS
    end

    it "checks only the tokens specified in the command line" do
      expect {
        Hbc::CLI::Outdated.run("local-caffeine")
      }.to output(<<-EOS.undent).to_stdout
        local-caffeine (1.2.2) != 1.2.3
      EOS
    end

    it 'ignores "auto_updates" and "latest" Casks even when their tokens are provided in the command line' do
      expect {
        Hbc::CLI::Outdated.run("local-caffeine", "auto-updates", "version-latest-string")
      }.to output(<<-EOS.undent).to_stdout
        local-caffeine (1.2.2) != 1.2.3
      EOS
    end
  end

  it "lists only the names (no versions) of the outdated Casks with --quiet" do
    expect {
      Hbc::CLI::Outdated.run("--quiet")
    }.to output(<<-EOS.undent).to_stdout
      local-caffeine
      local-transmission
    EOS
  end

  describe "with --greedy it checks additional Casks" do
    it 'includes the Casks with "auto_updates true" or "version latest" with --greedy' do
      expect {
        Hbc::CLI::Outdated.run("--greedy")
      }.to output(<<-EOS.undent).to_stdout
        auto-updates (2.57) != 2.61
        local-caffeine (1.2.2) != 1.2.3
        local-transmission (2.60) != 2.61
        version-latest-string (latest) != latest
      EOS
    end

    it 'does not include the Casks with "auto_updates true" when the version did not change' do
      cask = Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/auto-updates.rb")
      InstallHelper.install_with_caskfile(cask)

      expect {
        Hbc::CLI::Outdated.run("--greedy")
      }.to output(<<-EOS.undent).to_stdout
        local-caffeine (1.2.2) != 1.2.3
        local-transmission (2.60) != 2.61
        version-latest-string (latest) != latest
      EOS
    end
  end
end
