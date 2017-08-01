describe Hbc::CLI::Install, :cask do
  it "displays the installation progress" do
    output = Regexp.new <<-EOS.undent
      ==> Downloading file:.*caffeine.zip
      ==> Verifying checksum for Cask local-caffeine
      ==> Installing Cask local-caffeine
      ==> Moving App 'Caffeine.app' to '.*Caffeine.app'.
      .*local-caffeine was successfully installed!
    EOS

    expect {
      Hbc::CLI::Install.run("local-caffeine")
    }.to output(output).to_stdout
  end

  it "allows staging and activation of multiple Casks at once" do
    Hbc::CLI::Install.run("local-transmission", "local-caffeine")

    expect(Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/local-transmission.rb")).to be_installed
    expect(Hbc.appdir.join("Transmission.app")).to be_a_directory
    expect(Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/local-caffeine.rb")).to be_installed
    expect(Hbc.appdir.join("Caffeine.app")).to be_a_directory
  end

  it "skips double install (without nuking existing installation)" do
    Hbc::CLI::Install.run("local-transmission")
    Hbc::CLI::Install.run("local-transmission")
    expect(Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/local-transmission.rb")).to be_installed
  end

  it "prints a warning message on double install" do
    Hbc::CLI::Install.run("local-transmission")

    expect {
      Hbc::CLI::Install.run("local-transmission")
    }.to output(/Warning: Cask 'local-transmission' is already installed./).to_stderr
  end

  it "allows double install with --force" do
    Hbc::CLI::Install.run("local-transmission")

    expect {
      expect {
        Hbc::CLI::Install.run("local-transmission", "--force")
      }.to output(/It seems there is already an App at.*overwriting\./).to_stderr
    }.to output(/local-transmission was successfully installed!/).to_stdout
  end

  it "skips dependencies with --skip-cask-deps" do
    Hbc::CLI::Install.run("with-depends-on-cask-multiple", "--skip-cask-deps")
    expect(Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/with-depends-on-cask-multiple.rb")).to be_installed
    expect(Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/local-caffeine.rb")).not_to be_installed
    expect(Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/local-transmission.rb")).not_to be_installed
  end

  it "properly handles Casks that are not present" do
    expect {
      Hbc::CLI::Install.run("notacask")
    }.to raise_error(Hbc::CaskError, "Install incomplete.")
  end

  it "returns a suggestion for a misspelled Cask" do
    expect {
      begin
        Hbc::CLI::Install.run("localcaffeine")
      rescue Hbc::CaskError
        nil
      end
    }.to output(/Cask 'localcaffeine' is unavailable: No Cask with this name exists\. Did you mean:\nlocal-caffeine/).to_stderr
  end

  it "returns multiple suggestions for a Cask fragment" do
    expect {
      begin
        Hbc::CLI::Install.run("local-caf")
      rescue Hbc::CaskError
        nil
      end
    }.to output(/Cask 'local-caf' is unavailable: No Cask with this name exists\. Did you mean one of:\nlocal-caffeine/).to_stderr
  end

  describe "when no Cask is specified" do
    with_options = lambda do |options|
      it "raises an exception" do
        expect {
          Hbc::CLI::Install.run(*options)
        }.to raise_error(Hbc::CaskUnspecifiedError)
      end
    end

    describe "without options" do
      with_options.call([])
    end

    describe "with --force" do
      with_options.call(["--force"])
    end

    describe "with --skip-cask-deps" do
      with_options.call(["--skip-cask-deps"])
    end

    describe "with an invalid option" do
      it "raises an error" do
        expect {
          Hbc::CLI::Install.run("--notavalidoption")
        }.to raise_error(/invalid option/)
      end
    end
  end
end
