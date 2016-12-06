require "test_helper"

describe Hbc::CLI::Reinstall do
  it "allows reinstalling a Cask" do
    shutup do
      Hbc::CLI::Install.run("local-transmission")
    end
    Hbc.load("local-transmission").must_be :installed?

    shutup do
      Hbc::CLI::Reinstall.run("local-transmission")
    end
    Hbc.load("local-transmission").must_be :installed?
  end

  it "allows reinstalling a non installed Cask" do
    Hbc.load("local-transmission").wont_be :installed?

    shutup do
      Hbc::CLI::Reinstall.run("local-transmission")
    end
    Hbc.load("local-transmission").must_be :installed?
  end
end
