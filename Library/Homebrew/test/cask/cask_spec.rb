describe Cask::Cask, :cask do
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
    let(:tap_path) { Tap.default_cask_tap.path }
    let(:file_dirname) { Pathname.new(__FILE__).dirname }
    let(:relative_tap_path) { tap_path.relative_path_from(file_dirname) }

    it "returns an instance of the Cask for the given token" do
      c = Cask::CaskLoader.load("local-caffeine")
      expect(c).to be_kind_of(Cask::Cask)
      expect(c.token).to eq("local-caffeine")
    end

    it "returns an instance of the Cask from a specific file location" do
      c = Cask::CaskLoader.load("#{tap_path}/Casks/local-caffeine.rb")
      expect(c).to be_kind_of(Cask::Cask)
      expect(c.token).to eq("local-caffeine")
    end

    it "returns an instance of the Cask from a url" do
      c = Cask::CaskLoader.load("file://#{tap_path}/Casks/local-caffeine.rb")
      expect(c).to be_kind_of(Cask::Cask)
      expect(c.token).to eq("local-caffeine")
    end

    it "raises an error when failing to download a Cask from a url" do
      expect {
        url = "file://#{tap_path}/Casks/notacask.rb"

        Cask::CaskLoader.load(url)
      }.to raise_error(Cask::CaskUnavailableError)
    end

    it "returns an instance of the Cask from a relative file location" do
      c = Cask::CaskLoader.load(relative_tap_path/"Casks/local-caffeine.rb")
      expect(c).to be_kind_of(Cask::Cask)
      expect(c.token).to eq("local-caffeine")
    end

    it "uses exact match when loading by token" do
      expect(Cask::CaskLoader.load("test-opera").token).to eq("test-opera")
      expect(Cask::CaskLoader.load("test-opera-mail").token).to eq("test-opera-mail")
    end

    it "raises an error when attempting to load a Cask that doesn't exist" do
      expect {
        Cask::CaskLoader.load("notacask")
      }.to raise_error(Cask::CaskUnavailableError)
    end
  end

  describe "metadata" do
    it "proposes a versioned metadata directory name for each instance" do
      cask_token = "local-caffeine"
      c = Cask::CaskLoader.load(cask_token)
      metadata_timestamped_path = Cask::Caskroom.path.join(cask_token, ".metadata", c.version)
      expect(c.metadata_versioned_path.to_s).to eq(metadata_timestamped_path.to_s)
    end
  end

  describe "outdated" do
    it "ignores the Casks that have auto_updates true (without --greedy)" do
      c = Cask::CaskLoader.load("auto-updates")
      expect(c).not_to be_outdated
      expect(c.outdated_versions).to be_empty
    end

    it "ignores the Casks that have version :latest (without --greedy)" do
      c = Cask::CaskLoader.load("version-latest-string")
      expect(c).not_to be_outdated
      expect(c.outdated_versions).to be_empty
    end

    describe "versioned casks" do
      subject { cask.outdated_versions }

      let(:cask) { described_class.new("basic-cask") }

      shared_examples "versioned casks" do |tap_version, expectations|
        expectations.each do |installed_versions, expected_output|
          context "when versions #{installed_versions.inspect} are installed and the tap version is #{tap_version}" do
            it {
              allow(cask).to receive(:versions).and_return(installed_versions)
              allow(cask).to receive(:version).and_return(Cask::DSL::Version.new(tap_version))
              expect(cask).to receive(:outdated_versions).and_call_original
              expect(subject).to eq expected_output
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
          context "when versions #{installed_version} are installed and the " \
                  "tap version is #{tap_version}, #{"not" unless greedy} greedy" do
            subject { cask.outdated_versions greedy }

            it {
              allow(cask).to receive(:versions).and_return(installed_version)
              allow(cask).to receive(:version).and_return(Cask::DSL::Version.new(tap_version))
              expect(cask).to receive(:outdated_versions).and_call_original
              expect(subject).to eq expected_output
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

  describe "full_name" do
    context "when it is a core cask" do
      it "is the cask token" do
        c = Cask::CaskLoader.load("local-caffeine")
        expect(c.full_name).to eq("local-caffeine")
      end
    end

    context "when it is from a non-core tap" do
      it "returns the fully-qualified name of the cask" do
        c = Cask::CaskLoader.load("third-party/tap/third-party-cask")
        expect(c.full_name).to eq("third-party/tap/third-party-cask")
      end
    end

    context "when it is from no known tap" do
      it "retuns the cask token" do
        file = Tempfile.new(%w[tapless-cask .rb])

        begin
          cask_name = File.basename(file.path, ".rb")
          file.write "cask '#{cask_name}'"
          file.close

          c = Cask::CaskLoader.load(file.path)
          expect(c.full_name).to eq(cask_name)
        ensure
          file.close
          file.unlink
        end
      end
    end
  end
end
