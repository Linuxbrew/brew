describe Cask::Cmd::InternalStanza, :cask do
  it "shows stanza of the Specified Cask" do
    command = described_class.new("homepage", "local-caffeine")
    expect {
      command.run
    }.to output("https://example.com/local-caffeine\n").to_stdout
  end

  it "raises an exception when stanza is unknown/unsupported" do
    expect {
      described_class.new("this_stanza_does_not_exist", "local-caffeine")
    }.to raise_error(%r{Unknown/unsupported stanza})
  end

  it "raises an exception when normal stanza is not present on cask" do
    command = described_class.new("caveats", "local-caffeine")
    expect {
      command.run
    }.to raise_error(/no such stanza/)
  end

  it "raises an exception when artifact stanza is not present on cask" do
    command = described_class.new("zap", "local-caffeine")
    expect {
      command.run
    }.to raise_error(/no such stanza/)
  end

  it "raises an exception when 'depends_on' stanza is not present on cask" do
    command = described_class.new("depends_on", "local-caffeine")
    expect {
      command.run
    }.to raise_error(/no such stanza/)
  end

  it "shows all artifact stanzas when using 'artifacts' keyword" do
    command = described_class.new("artifacts", "local-caffeine")
    expect {
      command.run
    }.to output(/Caffeine\.app/).to_stdout
  end
end
