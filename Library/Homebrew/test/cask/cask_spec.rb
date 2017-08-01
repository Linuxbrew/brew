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
      c = Hbc::CaskLoader.load("local-caffeine")
      expect(c).to be_kind_of(Hbc::Cask)
      expect(c.token).to eq("local-caffeine")
    end

    it "returns an instance of the Cask from a specific file location" do
      c = Hbc::CaskLoader.load("#{tap_path}/Casks/local-caffeine.rb")
      expect(c).to be_kind_of(Hbc::Cask)
      expect(c.token).to eq("local-caffeine")
    end

    it "returns an instance of the Cask from a url" do
      c = Hbc::CaskLoader.load("file://#{tap_path}/Casks/local-caffeine.rb")
      expect(c).to be_kind_of(Hbc::Cask)
      expect(c.token).to eq("local-caffeine")
    end

    it "raises an error when failing to download a Cask from a url" do
      expect {
        url = "file://#{tap_path}/Casks/notacask.rb"

        Hbc::CaskLoader.load(url)
      }.to raise_error(Hbc::CaskUnavailableError)
    end

    it "returns an instance of the Cask from a relative file location" do
      c = Hbc::CaskLoader.load(relative_tap_path/"Casks/local-caffeine.rb")
      expect(c).to be_kind_of(Hbc::Cask)
      expect(c.token).to eq("local-caffeine")
    end

    it "uses exact match when loading by token" do
      expect(Hbc::CaskLoader.load("test-opera").token).to eq("test-opera")
      expect(Hbc::CaskLoader.load("test-opera-mail").token).to eq("test-opera-mail")
    end

    it "raises an error when attempting to load a Cask that doesn't exist" do
      expect {
        Hbc::CaskLoader.load("notacask")
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
      c = Hbc::CaskLoader.load(cask_token)
      metadata_timestamped_path = Hbc.caskroom.join(cask_token, ".metadata", c.version)
      expect(c.metadata_versioned_path.to_s).to eq(metadata_timestamped_path.to_s)
    end
  end

  describe "outdated" do
    it "ignores the Casks that have auto_updates true (without --greedy)" do
      c = Hbc::CaskLoader.load("auto-updates")
      expect(c).not_to be_outdated
      expect(c.outdated_versions).to be_empty
    end

    it "ignores the Casks that have version :latest (without --greedy)" do
      c = Hbc::CaskLoader.load("version-latest-string")
      expect(c).not_to be_outdated
      expect(c.outdated_versions).to be_empty
    end

    describe "versioned casks" do
      let(:cask) { described_class.new("basic-cask") }
      subject { cask.outdated_versions }

      shared_examples "versioned casks" do |tap_version, expectations|
        expectations.each do |installed_versions, expected_output|
          context "when versions #{installed_versions.inspect} are installed and the tap version is #{tap_version}" do
            it {
              allow(cask).to receive(:versions).and_return(installed_versions)
              allow(cask).to receive(:version).and_return(Hbc::DSL::Version.new(tap_version))
              expect(cask).to receive(:outdated_versions).and_call_original
              is_expected.to eq expected_output
            }
          end
        end
      end

      describe "installed version is equal to tap version => not outdated" do
        include_examples "versioned casks", "1.2.3",
                         ["1.2.3"]          => [],
                         ["1.2.4", "1.2.3"] => []
      end

      describe "installed version is different than tap version => outdated" do
        include_examples "versioned casks", "1.2.4",
                         ["1.2.3"]                   => ["1.2.3"],
                         ["1.2.4", "1.2.3"]          => ["1.2.3"],
                         ["1.2.2", "1.2.3"]          => ["1.2.2", "1.2.3"],
                         ["1.2.2", "1.2.4", "1.2.3"] => ["1.2.2", "1.2.3"]
      end
    end

    describe ":latest casks" do
      let(:cask) { described_class.new("basic-cask") }

      shared_examples ":latest cask" do |greedy, tap_version, expectations|
        expectations.each do |installed_version, expected_output|
          context "when versions #{installed_version} are installed and the tap version is #{tap_version}, #{greedy ? "" : "not"} greedy" do
            subject { cask.outdated_versions greedy }
            it {
              allow(cask).to receive(:versions).and_return(installed_version)
              allow(cask).to receive(:version).and_return(Hbc::DSL::Version.new(tap_version))
              expect(cask).to receive(:outdated_versions).and_call_original
              is_expected.to eq expected_output
            }
          end
        end
      end

      describe ":latest version installed, :latest version in tap" do
        include_examples ":latest cask", false, "latest",
                         ["latest"] => []
        include_examples ":latest cask", true, "latest",
                         ["latest"] => ["latest"]
      end

      describe "numbered version installed, :latest version in tap" do
        include_examples ":latest cask", false, "latest",
                         ["1.2.3"] => ["1.2.3"]
        include_examples ":latest cask", true, "latest",
                         ["1.2.3"] => ["1.2.3"]
      end

      describe "latest version installed, numbered version in tap" do
        include_examples ":latest cask", false, "1.2.3",
                         ["latest"] => ["latest"]
        include_examples ":latest cask", true, "1.2.3",
                         ["latest"] => ["latest"]
      end
    end
  end
end
