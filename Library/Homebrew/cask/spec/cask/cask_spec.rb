describe Hbc::Cask do
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
    let(:hbc_relative_tap_path) { "../../Taps/caskroom/homebrew-cask" }

    it "returns an instance of the Cask for the given token" do
      c = Hbc.load("adium")
      expect(c).to be_kind_of(Hbc::Cask)
      expect(c.token).to eq("adium")
    end

    it "returns an instance of the Cask from a specific file location" do
      location = File.expand_path(hbc_relative_tap_path + "/Casks/dia.rb")
      c = Hbc.load(location)
      expect(c).to be_kind_of(Hbc::Cask)
      expect(c.token).to eq("dia")
    end

    it "returns an instance of the Cask from a url" do
      url = "file://" + File.expand_path(hbc_relative_tap_path + "/Casks/dia.rb")
      c = shutup do
        Hbc.load(url)
      end
      expect(c).to be_kind_of(Hbc::Cask)
      expect(c.token).to eq("dia")
    end

    it "raises an error when failing to download a Cask from a url" do
      expect {
        url = "file://" + File.expand_path(hbc_relative_tap_path + "/Casks/notacask.rb")
        shutup do
          Hbc.load(url)
        end
      }.to raise_error(Hbc::CaskUnavailableError)
    end

    it "returns an instance of the Cask from a relative file location" do
      c = Hbc.load(hbc_relative_tap_path + "/Casks/bbedit.rb")
      expect(c).to be_kind_of(Hbc::Cask)
      expect(c.token).to eq("bbedit")
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
      cask_token = "adium"
      c = Hbc.load(cask_token)
      metadata_path = Hbc.caskroom.join(cask_token, ".metadata", c.version)
      expect(c.metadata_versioned_container_path.to_s).to eq(metadata_path.to_s)
    end
  end
end
