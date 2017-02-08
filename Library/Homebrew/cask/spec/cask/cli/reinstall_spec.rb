require "spec_helper"

describe Hbc::CLI::Reinstall do
  it "allows reinstalling a Cask" do
    shutup do
      Hbc::CLI::Install.run("local-transmission")
    end
    expect(Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/local-transmission.rb")).to be_installed

    shutup do
      Hbc::CLI::Reinstall.run("local-transmission")
    end
    expect(Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/local-transmission.rb")).to be_installed
  end

  it "allows reinstalling a non installed Cask" do
    expect(Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/local-transmission.rb")).not_to be_installed

    shutup do
      Hbc::CLI::Reinstall.run("local-transmission")
    end
    expect(Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/local-transmission.rb")).to be_installed
  end
end
