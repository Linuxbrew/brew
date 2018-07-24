describe Hbc::Container::Naked, :cask do
  it "saves files with spaces in them from uris with encoded spaces" do
    cask = Hbc::Cask.new("spacey") do
      url "http://example.com/kevin%20spacey.pkg"
      version "1.2"
    end

    path                 = Pathname("/tmp/downloads/kevin-spacey.pkg")
    expected_destination = cask.staged_path.join("kevin spacey.pkg")

    container = Hbc::Container::Naked.new(cask, path)

    expect(container).to receive(:system_command!)
      .with("/usr/bin/ditto", args: ["--", path, expected_destination])

    container.extract(to: cask.staged_path, basename: "kevin spacey.pkg")
  end
end
