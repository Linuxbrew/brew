describe Hbc::CLI::InternalStanza, :cask do
  it "shows stanza of the Specified Cask" do
    command = described_class.new("gpg", "with-gpg")
    expect {
      command.run
    }.to output("http://example.com/gpg-signature.asc\n").to_stdout
  end

  it "raises an exception when stanza is unknown/unsupported" do
    expect {
      described_class.new("this_stanza_does_not_exist", "with-gpg")
    }.to raise_error(%r{Unknown/unsupported stanza})
  end

  it "raises an exception when normal stanza is not present on cask" do
    command = described_class.new("caveats", "with-gpg")
    expect {
      command.run
    }.to raise_error(/no such stanza/)
  end

  it "raises an exception when artifact stanza is not present on cask" do
    command = described_class.new("zap", "with-gpg")
    expect {
      command.run
    }.to raise_error(/no such stanza/)
  end

  it "raises an exception when 'depends_on' stanza is not present on cask" do
    command = described_class.new("depends_on", "with-gpg")
    expect {
      command.run
    }.to raise_error(/no such stanza/)
  end

  it "shows all artifact stanzas when using 'artifacts' keyword" do
    command = described_class.new("artifacts", "with-gpg")
    expect {
      command.run
    }.to output(/Caffeine\.app/).to_stdout
  end
end
