describe Hbc::Container::Naked, :cask do
  it "saves files with spaces in them from uris with encoded spaces" do
    cask = Hbc::Cask.new("spacey") do
      url "http://example.com/kevin%20spacey.pkg"
      version "1.2"
    end

    path                 = "/tmp/downloads/kevin-spacey-1.2.pkg"
    expected_destination = cask.staged_path.join("kevin spacey.pkg")
    expected_command     = ["/usr/bin/ditto", "--", path, expected_destination]
    Hbc::FakeSystemCommand.stubs_command(expected_command)

    container = Hbc::Container::Naked.new(cask, path, Hbc::FakeSystemCommand)

    expect {
      container.extract
    }.not_to raise_error

    expect(Hbc::FakeSystemCommand.system_calls[expected_command]).to eq(1)
  end
end
