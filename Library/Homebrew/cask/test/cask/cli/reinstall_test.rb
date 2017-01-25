require "test_helper"

describe Hbc::CLI::Reinstall do
  it "allows reinstalling a Cask" do
    shutup do
      Hbc::CLI::Install.run("local-transmission")
    end
    Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/local-transmission.rb").must_be :installed?

    shutup do
      Hbc::CLI::Reinstall.run("local-transmission")
    end
    Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/local-transmission.rb").must_be :installed?
  end

  it "allows reinstalling a non installed Cask" do
    Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/local-transmission.rb").wont_be :installed?

    shutup do
      Hbc::CLI::Reinstall.run("local-transmission")
    end
    Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/local-transmission.rb").must_be :installed?
  end
end
