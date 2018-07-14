describe Hbc::Container::Naked, :cask do
  it "saves files with spaces in them from uris with encoded spaces" do
    cask = Hbc::Cask.new("spacey") do
      url "http://example.com/kevin%20spacey.pkg"
      version "1.2"
    end

    path                 = "/tmp/downloads/kevin-spacey-1.2.pkg"
    expected_destination = cask.staged_path.join("kevin spacey.pkg")

    container = Hbc::Container::Naked.new(cask, path, Hbc::FakeSystemCommand)

    Hbc::FakeSystemCommand.expects_command(
      ["/usr/bin/ditto", "--", path, expected_destination],
    )

    expect {
      container.extract
    }.not_to raise_error
  end
end
