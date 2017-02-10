require "spec_helper"

describe Hbc::CLI::Search do
  it "lists the available Casks that match the search term" do
    expect {
      Hbc::CLI::Search.run("photoshop")
    }.to output(<<-EOS.undent).to_stdout
      ==> Partial matches
      adobe-photoshop-cc
      adobe-photoshop-lightroom
    EOS
  end

  it "shows that there are no Casks matching a search term that did not result in anything" do
    expect {
      Hbc::CLI::Search.run("foo-bar-baz")
    }.to output("No Cask found for \"foo-bar-baz\".\n").to_stdout
  end

  it "lists all available Casks with no search term" do
    expect {
      Hbc::CLI::Search.run
    }.to output(/google-chrome/).to_stdout
  end

  it "ignores hyphens in search terms" do
    expect {
      Hbc::CLI::Search.run("goo-gle-chrome")
    }.to output(/google-chrome/).to_stdout
  end

  it "ignores hyphens in Cask tokens" do
    expect {
      Hbc::CLI::Search.run("googlechrome")
    }.to output(/google-chrome/).to_stdout
  end

  it "accepts multiple arguments" do
    expect {
      Hbc::CLI::Search.run("google chrome")
    }.to output(/google-chrome/).to_stdout
  end

  it "accepts a regexp argument" do
    expect {
      Hbc::CLI::Search.run("/^google-c[a-z]rome$/")
    }.to output("==> Regexp matches\ngoogle-chrome\n").to_stdout
  end

  it "Returns both exact and partial matches" do
    expect {
      Hbc::CLI::Search.run("mnemosyne")
    }.to output(/^==> Exact match\nmnemosyne\n==> Partial matches\nsubclassed-mnemosyne/).to_stdout
  end

  it "does not search the Tap name" do
    expect {
      Hbc::CLI::Search.run("caskroom")
    }.to output(/^No Cask found for "caskroom"\.\n/).to_stdout
  end
end
