require "test_helper"

describe Hbc::CLI::Reinstall do
  it "allows reinstalling a Cask" do
    Hbc::CLI::Install.run("local-transmission")
    Hbc.load("local-transmission").must_be :installed?
    Hbc::CLI::Reinstall.run("local-transmission")
    Hbc.load("local-transmission").must_be :installed?
  end

  it "allows reinstalling a non installed Cask" do
    Hbc::CLI::Uninstall.run("local-transmission")
    Hbc.load("local-transmission").wont_be :installed?
    Hbc::CLI::Reinstall.run("local-transmission")
    Hbc.load("local-transmission").must_be :installed?
  end
end
