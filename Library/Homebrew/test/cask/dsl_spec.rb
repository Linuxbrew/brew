describe Cask::DSL, :cask do
  let(:cask) { Cask::CaskLoader.load(cask_path(token.to_s)) }
  let(:token) { "basic-cask" }

  context "stanzas" do
    it "lets you set url, homepage, and version" do
      expect(cask.url.to_s).to eq("https://example.com/TestCask.dmg")
      expect(cask.homepage).to eq("https://example.com/")
      expect(cask.version.to_s).to eq("1.2.3")
    end
  end

  describe "when a Cask includes an unknown method" do
    let(:attempt_unknown_method) {
      lambda do
        Cask::Cask.new("unexpected-method-cask") do
          future_feature :not_yet_on_your_machine
        end
      end
    }

    it "prints a warning that it has encountered an unexpected method" do
      expected = Regexp.compile(<<~EOS.lines.map(&:chomp).join)
        (?m)
        Warning:
        .*
        Unexpected method 'future_feature' called on Cask unexpected-method-cask\\.
        .*
        https://github.com/Homebrew/homebrew-cask#reporting-bugs
      EOS

      expect {
        expect(attempt_unknown_method).not_to output.to_stdout
      }.to output(expected).to_stderr
    end

    it "will simply warn, not throw an exception" do
      expect {
        attempt_unknown_method.call
      }.not_to raise_error
    end
  end

  describe "header line" do
    context "when invalid" do
      let(:token) { "invalid/invalid-header-format" }

      it "raises an error" do
        expect { cask }.to raise_error(Cask::CaskUnreadableError)
      end
    end

    context "when token does not match the file name" do
      let(:token) { "invalid/invalid-header-token-mismatch" }

      it "raises an error" do
        expect {
          cask
        }.to raise_error(Cask::CaskTokenMismatchError, /header line does not match the file name/)
      end
    end

    context "when it contains no DSL version" do
      let(:token) { "no-dsl-version" }

      it "does not require a DSL version in the header" do
        expect(cask.token).to eq("no-dsl-version")
        expect(cask.url.to_s).to eq("https://example.com/TestCask.dmg")
        expect(cask.homepage).to eq("https://example.com/")
        expect(cask.version.to_s).to eq("1.2.3")
      end
    end
  end

  describe "name stanza" do
    it "lets you set the full name via a name stanza" do
      cask = Cask::Cask.new("name-cask") do
        name "Proper Name"
      end

      expect(cask.name).to eq([
                                "Proper Name",
                              ])
    end

    it "Accepts an array value to the name stanza" do
      cask = Cask::Cask.new("array-name-cask") do
        name ["Proper Name", "Alternate Name"]
      end

      expect(cask.name).to eq([
                                "Proper Name",
                                "Alternate Name",
                              ])
    end

    it "Accepts multiple name stanzas" do
      cask = Cask::Cask.new("multi-name-cask") do
        name "Proper Name"
        name "Alternate Name"
      end

      expect(cask.name).to eq([
                                "Proper Name",
                                "Alternate Name",
                              ])
    end
  end

  describe "sha256 stanza" do
    it "lets you set checksum via sha256" do
      cask = Cask::Cask.new("checksum-cask") do
        sha256 "imasha2"
      end

      expect(cask.sha256).to eq("imasha2")
    end
  end

  describe "language stanza" do
    it "allows multilingual casks" do
      cask = lambda do
        Cask::Cask.new("cask-with-apps") do
          language "zh" do
            sha256 "abc123"
            "zh-CN"
          end

          language "en-US", default: true do
            sha256 "xyz789"
            "en-US"
          end

          url "https://example.org/#{language}.zip"
        end
      end

      allow(MacOS).to receive(:languages).and_return(["zh"])
      expect(cask.call.language).to eq("zh-CN")
      expect(cask.call.sha256).to eq("abc123")
      expect(cask.call.url.to_s).to eq("https://example.org/zh-CN.zip")

      allow(MacOS).to receive(:languages).and_return(["zh-XX"])
      expect(cask.call.language).to eq("zh-CN")
      expect(cask.call.sha256).to eq("abc123")
      expect(cask.call.url.to_s).to eq("https://example.org/zh-CN.zip")

      allow(MacOS).to receive(:languages).and_return(["en"])
      expect(cask.call.language).to eq("en-US")
      expect(cask.call.sha256).to eq("xyz789")
      expect(cask.call.url.to_s).to eq("https://example.org/en-US.zip")

      allow(MacOS).to receive(:languages).and_return(["xx-XX"])
      expect(cask.call.language).to eq("en-US")
      expect(cask.call.sha256).to eq("xyz789")
      expect(cask.call.url.to_s).to eq("https://example.org/en-US.zip")

      allow(MacOS).to receive(:languages).and_return(["xx-XX", "zh", "en"])
      expect(cask.call.language).to eq("zh-CN")
      expect(cask.call.sha256).to eq("abc123")
      expect(cask.call.url.to_s).to eq("https://example.org/zh-CN.zip")

      allow(MacOS).to receive(:languages).and_return(["xx-XX", "en-US", "zh"])
      expect(cask.call.language).to eq("en-US")
      expect(cask.call.sha256).to eq("xyz789")
      expect(cask.call.url.to_s).to eq("https://example.org/en-US.zip")
    end

    it "returns an empty array if no languages are specified" do
      cask = lambda do
        Cask::Cask.new("cask-with-apps") do
          url "https://example.org/file.zip"
        end
      end

      expect(cask.call.languages).to be_empty
    end

    it "returns an array of available languages" do
      cask = lambda do
        Cask::Cask.new("cask-with-apps") do
          language "zh" do
            sha256 "abc123"
            "zh-CN"
          end

          language "en-US", default: true do
            sha256 "xyz789"
            "en-US"
          end

          url "https://example.org/file.zip"
        end
      end

      expect(cask.call.languages).to eq(["zh", "en-US"])
    end
  end

  describe "app stanza" do
    it "allows you to specify app stanzas" do
      cask = Cask::Cask.new("cask-with-apps") do
        app "Foo.app"
        app "Bar.app"
      end

      expect(cask.artifacts.map(&:to_s)).to eq(["Foo.app (App)", "Bar.app (App)"])
    end

    it "allow app stanzas to be empty" do
      cask = Cask::Cask.new("cask-with-no-apps")
      expect(cask.artifacts).to be_empty
    end
  end

  describe "caveats stanza" do
    it "allows caveats to be specified via a method define" do
      cask = Cask::Cask.new("plain-cask")

      expect(cask.caveats).to be_empty

      cask = Cask::Cask.new("cask-with-caveats") do
        def caveats
          <<~EOS
            When you install this Cask, you probably want to know this.
          EOS
        end
      end

      expect(cask.caveats).to eq("When you install this Cask, you probably want to know this.\n")
    end
  end

  describe "pkg stanza" do
    it "allows installable pkgs to be specified" do
      cask = Cask::Cask.new("cask-with-pkgs") do
        pkg "Foo.pkg"
        pkg "Bar.pkg"
      end

      expect(cask.artifacts.map(&:to_s)).to eq(["Foo.pkg (Pkg)", "Bar.pkg (Pkg)"])
    end
  end

  describe "url stanza" do
    let(:token) { "invalid/invalid-two-url" }

    it "prevents defining multiple urls" do
      expect { cask }.to raise_error(Cask::CaskInvalidError, /'url' stanza may only appear once/)
    end
  end

  describe "homepage stanza" do
    let(:token) { "invalid/invalid-two-homepage" }

    it "prevents defining multiple homepages" do
      expect { cask }.to raise_error(Cask::CaskInvalidError, /'homepage' stanza may only appear once/)
    end
  end

  describe "version stanza" do
    let(:token) { "invalid/invalid-two-version" }

    it "prevents defining multiple versions" do
      expect { cask }.to raise_error(Cask::CaskInvalidError, /'version' stanza may only appear once/)
    end
  end

  describe "appcast stanza" do
    let(:token) { "with-appcast" }

    it "allows appcasts to be specified" do
      expect(cask.appcast.to_s).to match(/^http/)
    end

    context "when multiple appcasts are defined" do
      let(:token) { "invalid/invalid-appcast-multiple" }

      it "raises an error" do
        expect { cask }.to raise_error(Cask::CaskInvalidError, /'appcast' stanza may only appear once/)
      end
    end

    context "when appcast URL is invalid" do
      let(:token) { "invalid/invalid-appcast-url" }

      it "refuses to load" do
        expect { cask }.to raise_error(Cask::CaskInvalidError)
      end
    end
  end

  describe "depends_on stanza" do
    let(:token) { "invalid/invalid-depends-on-key" }

    it "refuses to load with an invalid depends_on key" do
      expect { cask }.to raise_error(Cask::CaskInvalidError)
    end
  end

  describe "depends_on formula" do
    context "with one Formula" do
      let(:token) { "with-depends-on-formula" }

      it "allows depends_on formula to be specified" do
        expect(cask.depends_on.formula).not_to be nil
      end
    end

    context "with multiple Formulae" do
      let(:token) { "with-depends-on-formula-multiple" }

      it "allows multiple depends_on formula to be specified" do
        expect(cask.depends_on.formula).not_to be nil
      end
    end
  end

  describe "depends_on cask" do
    context "specifying one" do
      let(:token) { "with-depends-on-cask" }

      it "is allowed" do
        expect(cask.depends_on.cask).not_to be nil
      end
    end

    context "specifying multiple" do
      let(:token) { "with-depends-on-cask-multiple" }

      it "is allowed" do
        expect(cask.depends_on.cask).not_to be nil
      end
    end
  end

  describe "depends_on macos" do
    context "valid" do
      let(:token) { "with-depends-on-macos-string" }

      it "allows depends_on macos to be specified" do
        expect(cask.depends_on.macos).not_to be nil
      end
    end

    context "invalid depends_on macos value" do
      let(:token) { "invalid/invalid-depends-on-macos-bad-release" }

      it "refuses to load" do
        expect { cask }.to raise_error(Cask::CaskInvalidError)
      end
    end

    context "conflicting depends_on macos forms" do
      let(:token) { "invalid/invalid-depends-on-macos-conflicting-forms" }

      it "refuses to load" do
        expect { cask }.to raise_error(Cask::CaskInvalidError)
      end
    end
  end

  describe "depends_on arch" do
    context "valid" do
      let(:token) { "with-depends-on-arch" }

      it "is allowed to be specified" do
        expect(cask.depends_on.arch).not_to be nil
      end
    end

    context "invalid depends_on arch value" do
      let(:token) { "invalid/invalid-depends-on-arch-value" }

      it "refuses to load" do
        expect { cask }.to raise_error(Cask::CaskInvalidError)
      end
    end
  end

  describe "depends_on x11" do
    context "valid" do
      let(:token) { "with-depends-on-x11" }

      it "is allowed to be specified" do
        expect(cask.depends_on.x11).not_to be nil
      end
    end

    context "invalid depends_on x11 value" do
      let(:token) { "invalid/invalid-depends-on-x11-value" }

      it "refuses to load" do
        expect { cask }.to raise_error(Cask::CaskInvalidError)
      end
    end
  end

  describe "conflicts_with stanza" do
    context "valid" do
      let(:token) { "with-conflicts-with" }

      it "allows conflicts_with stanza to be specified" do
        expect(cask.conflicts_with.formula).not_to be nil
      end
    end

    context "invalid conflicts_with key" do
      let(:token) { "invalid/invalid-conflicts-with-key" }

      it "refuses to load invalid conflicts_with key" do
        expect { cask }.to raise_error(Cask::CaskInvalidError)
      end
    end
  end

  describe "installer stanza" do
    context "script" do
      let(:token) { "with-installer-script" }

      it "allows installer script to be specified" do
        expect(cask.artifacts.to_a.first.path).to eq(Pathname("/usr/bin/true"))
        expect(cask.artifacts.to_a.first.args[:args]).to eq(["--flag"])
        expect(cask.artifacts.to_a.second.path).to eq(Pathname("/usr/bin/false"))
        expect(cask.artifacts.to_a.second.args[:args]).to eq(["--flag"])
      end
    end

    context "manual" do
      let(:token) { "with-installer-manual" }

      it "allows installer manual to be specified" do
        installer = cask.artifacts.first
        expect(installer).to be_a(Cask::Artifact::Installer::ManualInstaller)
        expect(installer.path).to eq(Pathname("Caffeine.app"))
      end
    end
  end

  describe "stage_only stanza" do
    context "when there is no other activatable artifact" do
      let(:token) { "stage-only" }

      it "allows stage_only stanza to be specified" do
        expect(cask.artifacts).to contain_exactly a_kind_of Cask::Artifact::StageOnly
      end
    end

    context "when there is are activatable artifacts" do
      let(:token) { "invalid/invalid-stage-only-conflict" }

      it "prevents specifying stage_only" do
        expect { cask }.to raise_error(Cask::CaskInvalidError, /'stage_only' must be the only activatable artifact/)
      end
    end
  end

  describe "auto_updates stanza" do
    let(:token) { "auto-updates" }

    it "allows auto_updates stanza to be specified" do
      expect(cask.auto_updates).to be true
    end
  end

  describe "#appdir" do
    context "interpolation of the appdir in stanzas" do
      let(:token) { "appdir-interpolation" }

      it "is allowed" do
        expect(cask.artifacts.first.source).to eq(Cask::Config.global.appdir/"some/path")
      end
    end

    it "does not include a trailing slash" do
      begin
        original_appdir = Cask::Config.global.appdir
        Cask::Config.global.appdir = "#{original_appdir}/"

        cask = Cask::Cask.new("appdir-trailing-slash") do
          binary "#{appdir}/some/path"
        end

        expect(cask.artifacts.first.source).to eq(original_appdir/"some/path")
      ensure
        Cask::Config.global.appdir = original_appdir
      end
    end
  end

  describe "#artifacts" do
    it "sorts artifacts according to the preferable installation order" do
      cask = Cask::Cask.new("appdir-trailing-slash") do
        postflight do
          next
        end

        preflight do
          next
        end

        binary "binary"

        app "App.app"
      end

      expect(cask.artifacts.map(&:class).map(&:dsl_key)).to eq [
        :preflight,
        :app,
        :binary,
        :postflight,
      ]
    end
  end
end
