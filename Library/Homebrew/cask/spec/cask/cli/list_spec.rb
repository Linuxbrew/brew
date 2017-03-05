describe Hbc::CLI::List, :cask do
  it "lists the installed Casks in a pretty fashion" do
    casks = %w[local-caffeine local-transmission].map { |c| Hbc.load(c) }

    casks.each do |c|
      InstallHelper.install_with_caskfile(c)
    end

    expect {
      Hbc::CLI::List.run
    }.to output(<<-EOS.undent).to_stdout
      local-caffeine
      local-transmission
    EOS
  end

  describe "lists versions" do
    let(:casks) { ["local-caffeine", "local-transmission"] }
    let(:expected_output) {
      <<-EOS.undent
        local-caffeine 1.2.3
        local-transmission 2.61
      EOS
    }

    before(:each) do
      casks.map(&Hbc.method(:load)).each(&InstallHelper.method(:install_with_caskfile))
    end

    it "of all installed Casks" do
      expect {
        Hbc::CLI::List.run("--versions")
      }.to output(expected_output).to_stdout
    end

    it "of given Casks" do
      expect {
        Hbc::CLI::List.run("--versions", "local-caffeine", "local-transmission")
      }.to output(expected_output).to_stdout
    end
  end

  describe "when Casks have been renamed" do
    let(:caskroom_path) { Hbc.caskroom.join("ive-been-renamed") }
    let(:staged_path) { caskroom_path.join("latest") }

    before do
      staged_path.mkpath
    end

    it "lists installed Casks without backing ruby files (due to renames or otherwise)" do
      expect {
        Hbc::CLI::List.run
      }.to output(<<-EOS.undent).to_stdout
        ive-been-renamed (!)
      EOS
    end
  end

  describe "given a set of installed Casks" do
    let(:caffeine) { Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/local-caffeine.rb") }
    let(:transmission) { Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/local-transmission.rb") }
    let(:casks) { [caffeine, transmission] }

    it "lists the installed files for those Casks" do
      casks.each(&InstallHelper.method(:install_without_artifacts_with_caskfile))

      shutup do
        Hbc::Artifact::App.new(transmission).install_phase
      end

      expect {
        Hbc::CLI::List.run("local-transmission", "local-caffeine")
      }.to output(<<-EOS.undent).to_stdout
        ==> Apps
        #{Hbc.appdir.join("Transmission.app")} (#{Hbc.appdir.join("Transmission.app").abv})
        ==> Apps
        Missing App: #{Hbc.appdir.join("Caffeine.app")}
      EOS
    end
  end
end
