describe Hbc::Cask, :cask do
  let(:cask) { described_class.new("versioned-cask") }

  context "when multiple versions are installed" do
    describe "#versions" do
      context "and there are duplicate versions" do
        it "uses the last unique version" do
          allow(cask).to receive(:timestamped_versions).and_return([
                                                                     ["1.2.2", "0999"],
                                                                     ["1.2.3", "1000"],
                                                                     ["1.2.2", "1001"],
                                                                   ])

          expect(cask).to receive(:timestamped_versions)
          expect(cask.versions).to eq([
                                        "1.2.3",
                                        "1.2.2",
                                      ])
        end
      end
    end
  end

  describe "load" do
    let(:tap_path) { Hbc.default_tap.path }
    let(:file_dirname) { Pathname.new(__FILE__).dirname }
    let(:relative_tap_path) { tap_path.relative_path_from(file_dirname) }

    it "returns an instance of the Cask for the given token" do
      c = Hbc.load("local-caffeine")
      expect(c).to be_kind_of(Hbc::Cask)
      expect(c.token).to eq("local-caffeine")
    end

    it "returns an instance of the Cask from a specific file location" do
      c = Hbc.load("#{tap_path}/Casks/local-caffeine.rb")
      expect(c).to be_kind_of(Hbc::Cask)
      expect(c.token).to eq("local-caffeine")
    end

    it "returns an instance of the Cask from a url" do
      c = shutup do
        Hbc.load("file://#{tap_path}/Casks/local-caffeine.rb")
      end
      expect(c).to be_kind_of(Hbc::Cask)
      expect(c.token).to eq("local-caffeine")
    end

    it "raises an error when failing to download a Cask from a url" do
      expect {
        url = "file://#{tap_path}/Casks/notacask.rb"
        shutup do
          Hbc.load(url)
        end
      }.to raise_error(Hbc::CaskUnavailableError)
    end

    it "returns an instance of the Cask from a relative file location" do
      c = Hbc.load(relative_tap_path/"Casks/local-caffeine.rb")
      expect(c).to be_kind_of(Hbc::Cask)
      expect(c.token).to eq("local-caffeine")
    end

    it "uses exact match when loading by token" do
      expect(Hbc.load("test-opera").token).to eq("test-opera")
      expect(Hbc.load("test-opera-mail").token).to eq("test-opera-mail")
    end

    it "raises an error when attempting to load a Cask that doesn't exist" do
      expect {
        Hbc.load("notacask")
      }.to raise_error(Hbc::CaskUnavailableError)
    end
  end

  describe "all_tokens" do
    it "returns a token for every Cask" do
      all_cask_tokens = Hbc.all_tokens
      expect(all_cask_tokens.count).to be > 20
      all_cask_tokens.each { |token| expect(token).to be_kind_of(String) }
    end
  end

  describe "metadata" do
    it "proposes a versioned metadata directory name for each instance" do
      cask_token = "local-caffeine"
      c = Hbc.load(cask_token)
      metadata_path = Hbc.caskroom.join(cask_token, ".metadata", c.version)
      expect(c.metadata_versioned_container_path.to_s).to eq(metadata_path.to_s)
    end
  end
end
