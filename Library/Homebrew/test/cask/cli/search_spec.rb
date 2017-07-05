describe Hbc::CLI::Search, :cask do
  before(:each) do
    allow($stdout).to receive(:tty?).and_return(true)
  end

  it "lists the available Casks that match the search term" do
    expect {
      Hbc::CLI::Search.run("local")
    }.to output(<<-EOS.undent).to_stdout
      ==> Partial Matches
      local-caffeine
      local-transmission
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
    }.to output(/local-caffeine/).to_stdout
  end

  it "ignores hyphens in search terms" do
    expect {
      Hbc::CLI::Search.run("lo-cal-caffeine")
    }.to output(/local-caffeine/).to_stdout
  end

  it "ignores hyphens in Cask tokens" do
    expect {
      Hbc::CLI::Search.run("localcaffeine")
    }.to output(/local-caffeine/).to_stdout
  end

  it "accepts multiple arguments" do
    expect {
      Hbc::CLI::Search.run("local caffeine")
    }.to output(/local-caffeine/).to_stdout
  end

  it "accepts a regexp argument" do
    expect {
      Hbc::CLI::Search.run("/^local-c[a-z]ffeine$/")
    }.to output("==> Regexp Matches\nlocal-caffeine\n").to_stdout
  end

  it "Returns both exact and partial matches" do
    expect {
      Hbc::CLI::Search.run("test-opera")
    }.to output(/^==> Exact Match\ntest-opera\n==> Partial Matches\ntest-opera-mail/).to_stdout
  end

  it "does not search the Tap name" do
    expect {
      Hbc::CLI::Search.run("caskroom")
    }.to output(/^No Cask found for "caskroom"\.\n/).to_stdout
  end

  it "doesn't highlight packages that aren't installed" do
    expect(Hbc::CLI::Search.highlight_installed("local-caffeine")).to eq("local-caffeine")
  end

  it "highlights installed packages" do
    shutup do
      Hbc::CLI::Install.run("local-caffeine")
    end

    expect(Hbc::CLI::Search.highlight_installed("local-caffeine")).to eq(pretty_installed("local-caffeine"))
  end
end
