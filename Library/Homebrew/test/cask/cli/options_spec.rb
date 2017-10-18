describe Hbc::CLI, :cask do
  it "supports setting the appdir" do
    described_class.new.process_options("help", "--appdir=/some/path/foo")

    expect(Hbc.appdir).to eq(Pathname.new("/some/path/foo"))
  end

  it "supports setting the appdir from ENV" do
    ENV["HOMEBREW_CASK_OPTS"] = "--appdir=/some/path/bar"

    described_class.new.process_options("help")

    expect(Hbc.appdir).to eq(Pathname.new("/some/path/bar"))
  end

  it "supports setting the prefpanedir" do
    described_class.new.process_options("help", "--prefpanedir=/some/path/foo")

    expect(Hbc.prefpanedir).to eq(Pathname.new("/some/path/foo"))
  end

  it "supports setting the prefpanedir from ENV" do
    ENV["HOMEBREW_CASK_OPTS"] = "--prefpanedir=/some/path/bar"

    described_class.new.process_options("help")

    expect(Hbc.prefpanedir).to eq(Pathname.new("/some/path/bar"))
  end

  it "supports setting the qlplugindir" do
    described_class.new.process_options("help", "--qlplugindir=/some/path/foo")

    expect(Hbc.qlplugindir).to eq(Pathname.new("/some/path/foo"))
  end

  it "supports setting the qlplugindir from ENV" do
    ENV["HOMEBREW_CASK_OPTS"] = "--qlplugindir=/some/path/bar"

    described_class.new.process_options("help")

    expect(Hbc.qlplugindir).to eq(Pathname.new("/some/path/bar"))
  end

  it "supports setting the colorpickerdir" do
    described_class.new.process_options("help", "--colorpickerdir=/some/path/foo")

    expect(Hbc.colorpickerdir).to eq(Pathname.new("/some/path/foo"))
  end

  it "supports setting the colorpickerdir from ENV" do
    ENV["HOMEBREW_CASK_OPTS"] = "--colorpickerdir=/some/path/bar"

    described_class.new.process_options("help")

    expect(Hbc.colorpickerdir).to eq(Pathname.new("/some/path/bar"))
  end

  it "supports setting the dictionarydir" do
    described_class.new.process_options("help", "--dictionarydir=/some/path/foo")

    expect(Hbc.dictionarydir).to eq(Pathname.new("/some/path/foo"))
  end

  it "supports setting the dictionarydir from ENV" do
    ENV["HOMEBREW_CASK_OPTS"] = "--dictionarydir=/some/path/bar"

    described_class.new.process_options("help")

    expect(Hbc.dictionarydir).to eq(Pathname.new("/some/path/bar"))
  end

  it "supports setting the fontdir" do
    described_class.new.process_options("help", "--fontdir=/some/path/foo")

    expect(Hbc.fontdir).to eq(Pathname.new("/some/path/foo"))
  end

  it "supports setting the fontdir from ENV" do
    ENV["HOMEBREW_CASK_OPTS"] = "--fontdir=/some/path/bar"

    described_class.new.process_options("help")

    expect(Hbc.fontdir).to eq(Pathname.new("/some/path/bar"))
  end

  it "supports setting the servicedir" do
    described_class.new.process_options("help", "--servicedir=/some/path/foo")

    expect(Hbc.servicedir).to eq(Pathname.new("/some/path/foo"))
  end

  it "supports setting the servicedir from ENV" do
    ENV["HOMEBREW_CASK_OPTS"] = "--servicedir=/some/path/bar"

    described_class.new.process_options("help")

    expect(Hbc.servicedir).to eq(Pathname.new("/some/path/bar"))
  end

  it "allows additional options to be passed through" do
    rest = described_class.new.process_options("edit", "foo", "--create", "--appdir=/some/path/qux")

    expect(Hbc.appdir).to eq(Pathname.new("/some/path/qux"))
    expect(rest).to eq(%w[edit foo --create])
  end

  describe "--help" do
    it "sets the Cask help method to true" do
      command = described_class.new("foo", "--help")
      expect(command.help?).to be true
    end
  end
end
