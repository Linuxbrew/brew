describe Hbc::CLI, :cask do
  it "supports setting the appdir" do
    Hbc::CLI.process_options %w[help --appdir=/some/path/foo]

    expect(Hbc.appdir).to eq(Pathname.new("/some/path/foo"))
  end

  it "supports setting the appdir from ENV" do
    ENV["HOMEBREW_CASK_OPTS"] = "--appdir=/some/path/bar"

    Hbc::CLI.process_options %w[help]

    expect(Hbc.appdir).to eq(Pathname.new("/some/path/bar"))
  end

  it "supports setting the prefpanedir" do
    Hbc::CLI.process_options %w[help --prefpanedir=/some/path/foo]

    expect(Hbc.prefpanedir).to eq(Pathname.new("/some/path/foo"))
  end

  it "supports setting the prefpanedir from ENV" do
    ENV["HOMEBREW_CASK_OPTS"] = "--prefpanedir=/some/path/bar"

    Hbc::CLI.process_options %w[help]

    expect(Hbc.prefpanedir).to eq(Pathname.new("/some/path/bar"))
  end

  it "supports setting the qlplugindir" do
    Hbc::CLI.process_options %w[help --qlplugindir=/some/path/foo]

    expect(Hbc.qlplugindir).to eq(Pathname.new("/some/path/foo"))
  end

  it "supports setting the qlplugindir from ENV" do
    ENV["HOMEBREW_CASK_OPTS"] = "--qlplugindir=/some/path/bar"

    Hbc::CLI.process_options %w[help]

    expect(Hbc.qlplugindir).to eq(Pathname.new("/some/path/bar"))
  end

  it "supports setting the colorpickerdir" do
    Hbc::CLI.process_options %w[help --colorpickerdir=/some/path/foo]

    expect(Hbc.colorpickerdir).to eq(Pathname.new("/some/path/foo"))
  end

  it "supports setting the colorpickerdir from ENV" do
    ENV["HOMEBREW_CASK_OPTS"] = "--colorpickerdir=/some/path/bar"

    Hbc::CLI.process_options %w[help]

    expect(Hbc.colorpickerdir).to eq(Pathname.new("/some/path/bar"))
  end

  it "supports setting the dictionarydir" do
    Hbc::CLI.process_options %w[help --dictionarydir=/some/path/foo]

    expect(Hbc.dictionarydir).to eq(Pathname.new("/some/path/foo"))
  end

  it "supports setting the dictionarydir from ENV" do
    ENV["HOMEBREW_CASK_OPTS"] = "--dictionarydir=/some/path/bar"

    Hbc::CLI.process_options %w[help]

    expect(Hbc.dictionarydir).to eq(Pathname.new("/some/path/bar"))
  end

  it "supports setting the fontdir" do
    Hbc::CLI.process_options %w[help --fontdir=/some/path/foo]

    expect(Hbc.fontdir).to eq(Pathname.new("/some/path/foo"))
  end

  it "supports setting the fontdir from ENV" do
    ENV["HOMEBREW_CASK_OPTS"] = "--fontdir=/some/path/bar"

    Hbc::CLI.process_options %w[help]

    expect(Hbc.fontdir).to eq(Pathname.new("/some/path/bar"))
  end

  it "supports setting the servicedir" do
    Hbc::CLI.process_options %w[help --servicedir=/some/path/foo]

    expect(Hbc.servicedir).to eq(Pathname.new("/some/path/foo"))
  end

  it "supports setting the servicedir from ENV" do
    ENV["HOMEBREW_CASK_OPTS"] = "--servicedir=/some/path/bar"

    Hbc::CLI.process_options %w[help]

    expect(Hbc.servicedir).to eq(Pathname.new("/some/path/bar"))
  end

  it "allows additional options to be passed through" do
    rest = Hbc::CLI.process_options %w[edit foo --create --appdir=/some/path/qux]

    expect(Hbc.appdir).to eq(Pathname.new("/some/path/qux"))
    expect(rest).to eq(%w[edit foo --create])
  end

  describe "when a mandatory argument is missing" do
    it "shows a user-friendly error message" do
      expect {
        Hbc::CLI.process_options %w[install -f]
      }.to raise_error(ArgumentError)
    end
  end

  describe "given an ambiguous option" do
    it "shows a user-friendly error message" do
      expect {
        Hbc::CLI.process_options %w[edit -c]
      }.to raise_error(ArgumentError)
    end
  end

  describe "--help" do
    it "sets the Cask help method to true" do
      begin
        Hbc::CLI.process_options %w[foo --help]
        expect(Hbc::CLI.help?).to be true
      ensure
        Hbc::CLI.help = false
      end
    end
  end
end
