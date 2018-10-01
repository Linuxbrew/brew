require "formula"
require "formula_installer"
require "utils/bottles"

describe Formulary do
  let(:formula_name) { "testball_bottle" }
  let(:formula_path) { CoreTap.new.formula_dir/"#{formula_name}.rb" }
  let(:formula_content) do
    <<~RUBY
      class #{described_class.class_s(formula_name)} < Formula
        url "file://#{TEST_FIXTURE_DIR}/tarballs/testball-0.1.tbz"
        sha256 TESTBALL_SHA256

        bottle do
          cellar :any_skip_relocation
          root_url "file://#{bottle_dir}"
          sha256 "d48bbbe583dcfbfa608579724fc6f0328b3cd316935c6ea22f134610aaf2952f" => :#{Utils::Bottles.tag}
        end

        def install
          prefix.install "bin"
          prefix.install "libexec"
        end
      end
    RUBY
  end
  let(:bottle_dir) { Pathname.new("#{TEST_FIXTURE_DIR}/bottles") }
  let(:bottle) { bottle_dir/"testball_bottle-0.1.#{Utils::Bottles.tag}.bottle.tar.gz" }

  describe "::class_s" do
    it "replaces '+' with 'x'" do
      expect(described_class.class_s("foo++")).to eq("Fooxx")
    end

    it "converts a string with dots to PascalCase" do
      expect(described_class.class_s("shell.fm")).to eq("ShellFm")
    end

    it "converts a string with hyphens to PascalCase" do
      expect(described_class.class_s("pkg-config")).to eq("PkgConfig")
    end

    it "converts a string with a single letter separated by a hyphen to PascalCase" do
      expect(described_class.class_s("s-lang")).to eq("SLang")
    end

    it "converts a string with underscores to PascalCase" do
      expect(described_class.class_s("foo_bar")).to eq("FooBar")
    end

    it "replaces '@' with 'AT'" do
      expect(described_class.class_s("openssl@1.1")).to eq("OpensslAT11")
    end
  end

  describe "::factory" do
    before do
      formula_path.write formula_content
    end

    it "returns a Formula" do
      expect(described_class.factory(formula_name)).to be_kind_of(Formula)
    end

    it "returns a Formula when given a fully qualified name" do
      expect(described_class.factory("homebrew/core/#{formula_name}")).to be_kind_of(Formula)
    end

    it "raises an error if the Formula cannot be found" do
      expect {
        described_class.factory("not_existed_formula")
      }.to raise_error(FormulaUnavailableError)
    end

    it "raises an error if ref is nil" do
      expect {
        described_class.factory(nil)
      }.to raise_error(ArgumentError)
    end

    context "when the Formula has the wrong class" do
      let(:formula_name) { "giraffe" }
      let(:formula_content) do
        <<~RUBY
          class Wrong#{described_class.class_s(formula_name)} < Formula
          end
        RUBY
      end

      it "raises an error" do
        expect {
          described_class.factory(formula_name)
        }.to raise_error(FormulaClassUnavailableError)
      end
    end

    it "returns a Formula when given a path" do
      expect(described_class.factory(formula_path)).to be_kind_of(Formula)
    end

    it "returns a Formula when given a URL" do
      formula = described_class.factory("file://#{formula_path}")
      expect(formula).to be_kind_of(Formula)
    end

    context "when given a bottle" do
      subject(:formula) { described_class.factory(bottle) }

      it "returns a Formula" do
        expect(formula).to be_kind_of(Formula)
      end

      it "calling #local_bottle_path on the returned Formula returns the bottle path" do
        expect(formula.local_bottle_path).to eq(bottle.realpath)
      end
    end

    context "when given an alias" do
      subject(:formula) { described_class.factory("foo") }

      let(:alias_dir) { CoreTap.instance.alias_dir.tap(&:mkpath) }
      let(:alias_path) { alias_dir/"foo" }

      before do
        alias_dir.mkpath
        FileUtils.ln_s formula_path, alias_path
      end

      it "returns a Formula" do
        expect(formula).to be_kind_of(Formula)
      end

      it "calling #alias_path on the returned Formula returns the alias path" do
        expect(formula.alias_path).to eq(alias_path.to_s)
      end
    end

    context "with installed Formula" do
      before do
        allow(described_class).to receive(:loader_for).and_call_original
        stub_formula_loader formula("gcc") { url "gcc-1.0" }
        stub_formula_loader formula("patchelf") { url "patchelf-1.0" }
        allow(Formula["patchelf"]).to receive(:installed?).and_return(true)
      end

      let(:installed_formula) { described_class.factory(formula_path) }
      let(:installer) { FormulaInstaller.new(installed_formula) }

      it "returns a Formula when given a rack" do
        installer.install

        f = described_class.from_rack(installed_formula.rack)
        expect(f).to be_kind_of(Formula)
      end

      it "returns a Formula when given a Keg" do
        installer.install

        keg = Keg.new(installed_formula.prefix)
        f = described_class.from_keg(keg)
        expect(f).to be_kind_of(Formula)
      end
    end

    context "when loading from Tap" do
      let(:tap) { Tap.new("homebrew", "foo") }
      let(:another_tap) { Tap.new("homebrew", "bar") }
      let(:formula_path) { tap.path/"#{formula_name}.rb" }

      it "returns a Formula when given a name" do
        expect(described_class.factory(formula_name)).to be_kind_of(Formula)
      end

      it "returns a Formula from an Alias path" do
        alias_dir = tap.path/"Aliases"
        alias_dir.mkpath
        FileUtils.ln_s formula_path, alias_dir/"bar"
        expect(described_class.factory("bar")).to be_kind_of(Formula)
      end

      it "raises an error when the Formula cannot be found" do
        expect {
          described_class.factory("#{tap}/not_existed_formula")
        }.to raise_error(TapFormulaUnavailableError)
      end

      it "returns a Formula when given a fully qualified name" do
        expect(described_class.factory("#{tap}/#{formula_name}")).to be_kind_of(Formula)
      end

      it "raises an error if a Formula is in multiple Taps" do
        (another_tap.path/"#{formula_name}.rb").write formula_content

        expect {
          described_class.factory(formula_name)
        }.to raise_error(TapFormulaAmbiguityError)
      end
    end
  end

  specify "::from_contents" do
    expect(described_class.from_contents(formula_name, formula_path, formula_content)).to be_kind_of(Formula)
  end

  describe "::to_rack" do
    alias_matcher :exist, :be_exist

    let(:rack_path) { HOMEBREW_CELLAR/formula_name }

    context "when the Rack does not exist" do
      it "returns the Rack" do
        expect(described_class.to_rack(formula_name)).to eq(rack_path)
      end
    end

    context "when the Rack exists" do
      before do
        rack_path.mkpath
      end

      it "returns the Rack" do
        expect(described_class.to_rack(formula_name)).to eq(rack_path)
      end
    end

    it "raises an error if the Formula is not available" do
      expect {
        described_class.to_rack("a/b/#{formula_name}")
      }.to raise_error(TapFormulaUnavailableError)
    end
  end

  describe "::find_with_priority" do
    let(:core_path) { CoreTap.new.formula_dir/"#{formula_name}.rb" }
    let(:tap) { Tap.new("homebrew", "foo") }
    let(:tap_path) { tap.path/"#{formula_name}.rb" }

    before do
      core_path.write formula_content
      tap_path.write formula_content
    end

    it "prioritizes core Formulae" do
      formula = described_class.find_with_priority(formula_name)
      expect(formula.path).to eq(core_path)
    end

    it "prioritizes Formulae from pinned Taps" do
      tap.pin
      formula = described_class.find_with_priority(formula_name)
      expect(formula.path).to eq(tap_path.realpath)
    end
  end

  describe "::core_path" do
    it "returns the path to a Formula in the core tap" do
      name = "foo-bar"
      expect(described_class.core_path(name))
        .to eq(Pathname.new("#{HOMEBREW_LIBRARY}/Taps/homebrew/homebrew-core/Formula/#{name}.rb"))
    end
  end
end
