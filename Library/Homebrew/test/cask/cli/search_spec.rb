describe Hbc::CLI::Search, :cask do
  before(:each) do
    allow(Tty).to receive(:width).and_return(0)
  end

  it "lists the available Casks that match the search term" do
    expect {
      Hbc::CLI::Search.run("local")
    }.to output(<<-EOS.undent).to_stdout.as_tty
      ==> Partial Matches
      local-caffeine
      local-transmission
    EOS
  end

  it "outputs a plain list when stdout is not a TTY" do
    expect {
      Hbc::CLI::Search.run("local")
    }.to output(<<-EOS.undent).to_stdout
      local-caffeine
      local-transmission
    EOS
  end

  it "shows that there are no Casks matching a search term that did not result in anything" do
    expect {
      Hbc::CLI::Search.run("foo-bar-baz")
    }.to output("No Cask found for \"foo-bar-baz\".\n").to_stdout.as_tty
  end

  it "lists all available Casks with no search term" do
    expect {
      Hbc::CLI::Search.run
    }.to output(/local-caffeine/).to_stdout.as_tty
  end

  it "ignores hyphens in search terms" do
    expect {
      Hbc::CLI::Search.run("lo-cal-caffeine")
    }.to output(/local-caffeine/).to_stdout.as_tty
  end

  it "ignores hyphens in Cask tokens" do
    expect {
      Hbc::CLI::Search.run("localcaffeine")
    }.to output(/local-caffeine/).to_stdout.as_tty
  end

  it "accepts multiple arguments" do
    expect {
      Hbc::CLI::Search.run("local caffeine")
    }.to output(/local-caffeine/).to_stdout.as_tty
  end

  it "accepts a regexp argument" do
    expect {
      Hbc::CLI::Search.run("/^local-c[a-z]ffeine$/")
    }.to output("==> Regexp Matches\nlocal-caffeine\n").to_stdout.as_tty
  end

  it "Returns both exact and partial matches" do
    expect {
      Hbc::CLI::Search.run("test-opera")
    }.to output(/^==> Exact Match\ntest-opera\n==> Partial Matches\ntest-opera-mail/).to_stdout.as_tty
  end

  it "does not search the Tap name" do
    expect {
      Hbc::CLI::Search.run("caskroom")
    }.to output(/^No Cask found for "caskroom"\.\n/).to_stdout.as_tty
  end

  it "doesn't highlight packages that aren't installed" do
    expect(Hbc::CLI::Search.highlight_installed("local-caffeine")).to eq("local-caffeine")
  end

  it "highlights installed packages" do
    Hbc::CLI::Install.run("local-caffeine")

    expect(Hbc::CLI::Search.highlight_installed("local-caffeine")).to eq(pretty_installed("local-caffeine"))
  end
end
