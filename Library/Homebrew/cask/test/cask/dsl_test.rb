require "test_helper"

describe Hbc::DSL do
  it "lets you set url, homepage, and version" do
    test_cask = Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/basic-cask.rb")
    test_cask.url.to_s.must_equal "http://example.com/TestCask.dmg"
    test_cask.homepage.must_equal "http://example.com/"
    test_cask.version.to_s.must_equal "1.2.3"
  end

  describe "when a Cask includes an unknown method" do
    attempt_unknown_method = nil

    before do
      attempt_unknown_method = lambda do
        Hbc::Cask.new("unexpected-method-cask") do
          future_feature :not_yet_on_your_machine
        end
      end
    end

    it "prints a warning that it has encountered an unexpected method" do
      expected = Regexp.compile(<<-EOS.undent.lines.map(&:chomp).join(""))
        (?m)
        Warning:
        .*
        Unexpected method 'future_feature' called on Cask unexpected-method-cask\\.
        .*
        https://github.com/caskroom/homebrew-cask/blob/master/doc/reporting_bugs/pre_bug_report.md
        .*
        https://github.com/caskroom/homebrew-cask#reporting-bugs
      EOS

      attempt_unknown_method.must_output nil, expected
    end

    it "will simply warn, not throw an exception" do
      begin
        shutup do
          attempt_unknown_method.call
        end
      rescue StandardError => e
        flunk("Wanted unexpected method to simply warn, but got exception #{e}")
      end
    end
  end

  describe "header line" do
    it "requires a valid header format" do
      lambda {
        Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/invalid/invalid-header-format.rb")
      }.must_raise(SyntaxError)
    end

    it "requires the header token to match the file name" do
      err = lambda {
        Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/invalid/invalid-header-token-mismatch.rb")
      }.must_raise(Hbc::CaskTokenDoesNotMatchError)
      err.message.must_include "Bad header line:"
      err.message.must_include "does not match file name"
    end

    it "does not require a DSL version in the header" do
      test_cask = Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/no-dsl-version.rb")
      test_cask.token.must_equal "no-dsl-version"
      test_cask.url.to_s.must_equal "http://example.com/TestCask.dmg"
      test_cask.homepage.must_equal "http://example.com/"
      test_cask.version.to_s.must_equal "1.2.3"
    end

    it "may use deprecated DSL version hash syntax" do
      stub = proc do |arg|
        arg == "HOMEBREW_DEVELOPER" ? nil : ENV[arg]
      end

      ENV.stub :[], stub do
        shutup do
          test_cask = Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/with-dsl-version.rb")
          test_cask.token.must_equal "with-dsl-version"
          test_cask.url.to_s.must_equal "http://example.com/TestCask.dmg"
          test_cask.homepage.must_equal "http://example.com/"
          test_cask.version.to_s.must_equal "1.2.3"
        end
      end
    end
  end

  describe "name stanza" do
    it "lets you set the full name via a name stanza" do
      cask = Hbc::Cask.new("name-cask") do
        name "Proper Name"
      end

      cask.name.must_equal [
        "Proper Name",
      ]
    end

    it "Accepts an array value to the name stanza" do
      cask = Hbc::Cask.new("array-name-cask") do
        name ["Proper Name", "Alternate Name"]
      end

      cask.name.must_equal [
        "Proper Name",
        "Alternate Name",
      ]
    end

    it "Accepts multiple name stanzas" do
      cask = Hbc::Cask.new("multi-name-cask") do
        name "Proper Name"
        name "Alternate Name"
      end

      cask.name.must_equal [
        "Proper Name",
        "Alternate Name",
      ]
    end
  end

  describe "sha256 stanza" do
    it "lets you set checksum via sha256" do
      cask = Hbc::Cask.new("checksum-cask") do
        sha256 "imasha2"
      end

      cask.sha256.must_equal "imasha2"
    end
  end

  describe "language stanza" do
    it "allows multilingual casks" do
      cask = lambda do
        Hbc::Cask.new("cask-with-apps") do
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

      MacOS.stub :languages, ["zh"] do
        cask.call.language.must_equal "zh-CN"
        cask.call.sha256.must_equal "abc123"
        cask.call.url.to_s.must_equal "https://example.org/zh-CN.zip"
      end

      MacOS.stub :languages, ["zh-XX"] do
        cask.call.language.must_equal "zh-CN"
        cask.call.sha256.must_equal "abc123"
        cask.call.url.to_s.must_equal "https://example.org/zh-CN.zip"
      end

      MacOS.stub :languages, ["en"] do
        cask.call.language.must_equal "en-US"
        cask.call.sha256.must_equal "xyz789"
        cask.call.url.to_s.must_equal "https://example.org/en-US.zip"
      end

      MacOS.stub :languages, ["xx-XX"] do
        cask.call.language.must_equal "en-US"
        cask.call.sha256.must_equal "xyz789"
        cask.call.url.to_s.must_equal "https://example.org/en-US.zip"
      end

      MacOS.stub :languages, ["xx-XX", "zh", "en"] do
        cask.call.language.must_equal "zh-CN"
        cask.call.sha256.must_equal "abc123"
        cask.call.url.to_s.must_equal "https://example.org/zh-CN.zip"
      end

      MacOS.stub :languages, ["xx-XX", "en-US", "zh"] do
        cask.call.language.must_equal "en-US"
        cask.call.sha256.must_equal "xyz789"
        cask.call.url.to_s.must_equal "https://example.org/en-US.zip"
      end
    end
  end

  describe "app stanza" do
    it "allows you to specify app stanzas" do
      cask = Hbc::Cask.new("cask-with-apps") do
        app "Foo.app"
        app "Bar.app"
      end

      Array(cask.artifacts[:app]).must_equal [["Foo.app"], ["Bar.app"]]
    end

    it "allow app stanzas to be empty" do
      cask = Hbc::Cask.new("cask-with-no-apps")
      Array(cask.artifacts[:app]).must_equal %w[]
    end
  end

  describe "caveats stanza" do
    it "allows caveats to be specified via a method define" do
      cask = Hbc::Cask.new("plain-cask")

      cask.caveats.must_be :empty?

      cask = Hbc::Cask.new("cask-with-caveats") do
        def caveats; <<-EOS.undent
          When you install this Cask, you probably want to know this.
          EOS
        end
      end

      cask.caveats.must_equal "When you install this Cask, you probably want to know this.\n"
    end
  end

  describe "pkg stanza" do
    it "allows installable pkgs to be specified" do
      cask = Hbc::Cask.new("cask-with-pkgs") do
        pkg "Foo.pkg"
        pkg "Bar.pkg"
      end

      Array(cask.artifacts[:pkg]).must_equal [["Foo.pkg"], ["Bar.pkg"]]
    end
  end

  describe "url stanza" do
    it "prevents defining multiple urls" do
      err = lambda {
        Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/invalid/invalid-two-url.rb")
      }.must_raise(Hbc::CaskInvalidError)
      err.message.must_include "'url' stanza may only appear once"
    end
  end

  describe "homepage stanza" do
    it "prevents defining multiple homepages" do
      err = lambda {
        Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/invalid/invalid-two-homepage.rb")
      }.must_raise(Hbc::CaskInvalidError)
      err.message.must_include "'homepage' stanza may only appear once"
    end
  end

  describe "version stanza" do
    it "prevents defining multiple versions" do
      err = lambda {
        Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/invalid/invalid-two-version.rb")
      }.must_raise(Hbc::CaskInvalidError)
      err.message.must_include "'version' stanza may only appear once"
    end
  end

  describe "appcast stanza" do
    it "allows appcasts to be specified" do
      cask = Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/with-appcast.rb")
      cask.appcast.to_s.must_match(/^http/)
    end

    it "prevents defining multiple appcasts" do
      err = lambda {
        Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/invalid/invalid-appcast-multiple.rb")
      }.must_raise(Hbc::CaskInvalidError)
      err.message.must_include "'appcast' stanza may only appear once"
    end

    it "refuses to load invalid appcast URLs" do
      lambda {
        Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/invalid/invalid-appcast-url.rb")
      }.must_raise(Hbc::CaskInvalidError)
    end
  end

  describe "gpg stanza" do
    it "allows gpg stanza to be specified" do
      cask = Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/with-gpg.rb")
      cask.gpg.to_s.must_match(/\S/)
    end

    it "allows gpg stanza to be specified with :key_url" do
      cask = Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/with-gpg-key-url.rb")
      cask.gpg.to_s.must_match(/\S/)
    end

    it "prevents specifying gpg stanza multiple times" do
      err = lambda {
        Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/invalid/invalid-gpg-multiple-stanzas.rb")
      }.must_raise(Hbc::CaskInvalidError)
      err.message.must_include "'gpg' stanza may only appear once"
    end

    it "prevents missing gpg key parameters" do
      err = lambda {
        Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/invalid/invalid-gpg-missing-key.rb")
      }.must_raise(Hbc::CaskInvalidError)
      err.message.must_include "'gpg' stanza must include exactly one"
    end

    it "prevents conflicting gpg key parameters" do
      err = lambda {
        Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/invalid/invalid-gpg-conflicting-keys.rb")
      }.must_raise(Hbc::CaskInvalidError)
      err.message.must_include "'gpg' stanza must include exactly one"
    end

    it "refuses to load invalid gpg signature URLs" do
      lambda {
        Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/invalid/invalid-gpg-signature-url.rb")
      }.must_raise(Hbc::CaskInvalidError)
    end

    it "refuses to load invalid gpg key URLs" do
      lambda {
        Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/invalid/invalid-gpg-key-url.rb")
      }.must_raise(Hbc::CaskInvalidError)
    end

    it "refuses to load invalid gpg key IDs" do
      lambda {
        Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/invalid/invalid-gpg-key-id.rb")
      }.must_raise(Hbc::CaskInvalidError)
    end

    it "refuses to load if gpg parameter is unknown" do
      lambda {
        Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/invalid/invalid-gpg-parameter.rb")
      }.must_raise(Hbc::CaskInvalidError)
    end
  end

  describe "depends_on stanza" do
    it "refuses to load with an invalid depends_on key" do
      lambda {
        Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/invalid/invalid-depends-on-key.rb")
      }.must_raise(Hbc::CaskInvalidError)
    end
  end

  describe "depends_on formula" do
    it "allows depends_on formula to be specified" do
      cask = Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/with-depends-on-formula.rb")
      cask.depends_on.formula.wont_be_nil
    end

    it "allows multiple depends_on formula to be specified" do
      cask = Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/with-depends-on-formula-multiple.rb")
      cask.depends_on.formula.wont_be_nil
    end
  end

  describe "depends_on cask" do
    it "allows depends_on cask to be specified" do
      cask = Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/with-depends-on-cask.rb")
      cask.depends_on.cask.wont_be_nil
    end

    it "allows multiple depends_on cask to be specified" do
      cask = Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/with-depends-on-cask-multiple.rb")
      cask.depends_on.cask.wont_be_nil
    end
  end

  describe "depends_on macos" do
    it "allows depends_on macos to be specified" do
      cask = Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/with-depends-on-macos-string.rb")
      cask.depends_on.macos.wont_be_nil
    end
    it "refuses to load with an invalid depends_on macos value" do
      lambda {
        Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/invalid/invalid-depends-on-macos-bad-release.rb")
      }.must_raise(Hbc::CaskInvalidError)
    end
    it "refuses to load with conflicting depends_on macos forms" do
      lambda {
        Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/invalid/invalid-depends-on-macos-conflicting-forms.rb")
      }.must_raise(Hbc::CaskInvalidError)
    end
  end

  describe "depends_on arch" do
    it "allows depends_on arch to be specified" do
      cask = Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/with-depends-on-arch.rb")
      cask.depends_on.arch.wont_be_nil
    end
    it "refuses to load with an invalid depends_on arch value" do
      lambda {
        Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/invalid/invalid-depends-on-arch-value.rb")
      }.must_raise(Hbc::CaskInvalidError)
    end
  end

  describe "depends_on x11" do
    it "allows depends_on x11 to be specified" do
      cask = Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/with-depends-on-x11.rb")
      cask.depends_on.x11.wont_be_nil
    end
    it "refuses to load with an invalid depends_on x11 value" do
      lambda {
        Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/invalid/invalid-depends-on-x11-value.rb")
      }.must_raise(Hbc::CaskInvalidError)
    end
  end

  describe "conflicts_with stanza" do
    it "allows conflicts_with stanza to be specified" do
      cask = Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/with-conflicts-with.rb")
      cask.conflicts_with.formula.wont_be_nil
    end

    it "refuses to load invalid conflicts_with key" do
      lambda {
        Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/invalid/invalid-conflicts-with-key.rb")
      }.must_raise(Hbc::CaskInvalidError)
    end
  end

  describe "installer stanza" do
    it "allows installer script to be specified" do
      cask = Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/with-installer-script.rb")
      cask.artifacts[:installer].first.script[:executable].must_equal "/usr/bin/true"
      cask.artifacts[:installer].first.script[:args].must_equal ["--flag"]
      cask.artifacts[:installer].to_a[1].script[:executable].must_equal "/usr/bin/false"
      cask.artifacts[:installer].to_a[1].script[:args].must_equal ["--flag"]
    end
    it "allows installer manual to be specified" do
      cask = Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/with-installer-manual.rb")
      cask.artifacts[:installer].first.manual.must_equal "Caffeine.app"
    end
  end

  describe "stage_only stanza" do
    it "allows stage_only stanza to be specified" do
      cask = Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/stage-only.rb")
      cask.artifacts[:stage_only].first.must_equal [true]
    end

    it "prevents specifying stage_only with other activatables" do
      err = lambda {
        Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/invalid/invalid-stage-only-conflict.rb")
      }.must_raise(Hbc::CaskInvalidError)
      err.message.must_include "'stage_only' must be the only activatable artifact"
    end
  end

  describe "auto_updates stanza" do
    it "allows auto_updates stanza to be specified" do
      cask = Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/auto-updates.rb")
      cask.auto_updates.must_equal true
    end
  end

  describe "appdir" do
    it "allows interpolation of the appdir value in stanzas" do
      cask = Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/appdir-interpolation.rb")
      cask.artifacts[:binary].first.must_equal ["#{Hbc.appdir}/some/path"]
    end

    it "does not include a trailing slash" do
      original_appdir = Hbc.appdir
      Hbc.appdir = "#{original_appdir}/"

      begin
        cask = Hbc::Cask.new("appdir-trailing-slash") do
          binary "#{appdir}/some/path"
        end

        cask.artifacts[:binary].first.must_equal ["#{original_appdir}/some/path"]
      ensure
        Hbc.appdir = original_appdir
      end
    end
  end
end
