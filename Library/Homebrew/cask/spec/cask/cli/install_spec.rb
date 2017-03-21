require "spec_helper"

describe Hbc::CLI::Install do
  it "allows staging and activation of multiple Casks at once" do
    shutup do
      Hbc::CLI::Install.run("local-transmission", "local-caffeine")
    end

    expect(Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/local-transmission.rb")).to be_installed
    expect(Hbc.appdir.join("Transmission.app")).to be_a_directory
    expect(Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/local-caffeine.rb")).to be_installed
    expect(Hbc.appdir.join("Caffeine.app")).to be_a_directory
  end

  it "skips double install (without nuking existing installation)" do
    shutup do
      Hbc::CLI::Install.run("local-transmission")
    end
    shutup do
      Hbc::CLI::Install.run("local-transmission")
    end
    expect(Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/local-transmission.rb")).to be_installed
  end

  it "prints a warning message on double install" do
    shutup do
      Hbc::CLI::Install.run("local-transmission")
    end

    expect {
      Hbc::CLI::Install.run("local-transmission", "")
    }.to output(/Warning: A Cask for local-transmission is already installed./).to_stderr
  end

  it "allows double install with --force" do
    shutup do
      Hbc::CLI::Install.run("local-transmission")
    end

    expect {
      expect {
        Hbc::CLI::Install.run("local-transmission", "--force")
      }.to output(/It seems there is already an App at.*overwriting\./).to_stderr
    }.to output(/local-transmission was successfully installed!/).to_stdout
  end

  it "skips dependencies with --skip-cask-deps" do
    shutup do
      Hbc::CLI::Install.run("with-depends-on-cask-multiple", "--skip-cask-deps")
    end
    expect(Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/with-depends-on-cask-multiple.rb")).to be_installed
    expect(Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/local-caffeine.rb")).not_to be_installed
    expect(Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/local-transmission.rb")).not_to be_installed
  end

  it "properly handles Casks that are not present" do
    expect {
      shutup do
        Hbc::CLI::Install.run("notacask")
      end
    }.to raise_error(Hbc::CaskError)
  end

  it "returns a suggestion for a misspelled Cask" do
    expect {
      begin
        Hbc::CLI::Install.run("googlechrome")
      rescue Hbc::CaskError
        nil
      end
    }.to output(/No available Cask for googlechrome\. Did you mean:\ngoogle-chrome/).to_stderr
  end

  it "returns multiple suggestions for a Cask fragment" do
    expect {
      begin
        Hbc::CLI::Install.run("google")
      rescue Hbc::CaskError
        nil
      end
    }.to output(/No available Cask for google\. Did you mean one of:\ngoogle/).to_stderr
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
      with_options.call(["--notavalidoption"])
    end
  end
end
