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

  it "returns matches even when online search failed" do
    allow(GitHub).to receive(:search_code).and_raise(GitHub::Error.new("reason"))
    expect {
      Hbc::CLI::Search.run("local")
    }.to output(<<-EOS.undent).to_stdout
      local-caffeine
      local-transmission
    EOS
    .and output(/^Warning: Error searching on GitHub: reason/).to_stderr
  end

  it "shows that there are no Casks matching a search term that did not result in anything" do
    expect {
      Hbc::CLI::Search.run("foo-bar-baz")
    }.to output(<<-EOS.undent).to_stdout.as_tty
      No Cask found for "foo-bar-baz".
    EOS
  end

  it "doesn't output anything to non-TTY stdout when there are no matches" do
    expect { Hbc::CLI::Search.run("foo-bar-baz") }
      .to not_to_output.to_stdout
      .and not_to_output.to_stderr
  end

  it "lists all Casks available offline with no search term" do
    allow(GitHub).to receive(:search_code).and_raise(GitHub::Error.new("reason"))
    expect { Hbc::CLI::Search.run }
      .to output(/local-caffeine/).to_stdout.as_tty
      .and not_to_output.to_stderr
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
    }.to output(<<-EOS.undent).to_stdout.as_tty
      ==> Regexp Matches
      local-caffeine
    EOS
  end

  it "returns both exact and partial matches" do
    expect {
      Hbc::CLI::Search.run("test-opera")
    }.to output(<<-EOS.undent).to_stdout.as_tty
      ==> Exact Match
      test-opera
      ==> Partial Matches
      test-opera-mail
    EOS
  end

  it "does not search the Tap name" do
    expect {
      Hbc::CLI::Search.run("caskroom")
    }.to output(<<-EOS.undent).to_stdout.as_tty
      No Cask found for "caskroom".
    EOS
  end

  it "doesn't highlight packages that aren't installed" do
    expect(Hbc::CLI::Search.highlight_installed("local-caffeine")).to eq("local-caffeine")
  end

  it "highlights installed packages" do
    Hbc::CLI::Install.run("local-caffeine")

    expect(Hbc::CLI::Search.highlight_installed("local-caffeine")).to eq(pretty_installed("local-caffeine"))
  end
end
