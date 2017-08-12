require "formula"
require "formula_installer"
require "utils/bottles"

describe Formulary do
  let(:formula_name) { "testball_bottle" }
  let(:formula_path) { CoreTap.new.formula_dir/"#{formula_name}.rb" }
  let(:formula_content) do
    <<-EOS.undent
      class #{subject.class_s(formula_name)} < Formula
        url "file://#{TEST_FIXTURE_DIR}/tarballs/testball-0.1.tbz"
        sha256 TESTBALL_SHA256

        bottle do
          cellar :any_skip_relocation
          root_url "file://#{bottle_dir}"
          sha256 "9abc8ce779067e26556002c4ca6b9427b9874d25f0cafa7028e05b5c5c410cb4" => :#{Utils::Bottles.tag}
        end

        def install
          prefix.install "bin"
          prefix.install "libexec"
        end
      end
    EOS
  end
  let(:bottle_dir) { Pathname.new("#{TEST_FIXTURE_DIR}/bottles") }
  let(:bottle) { bottle_dir/"testball_bottle-0.1.#{Utils::Bottles.tag}.bottle.tar.gz" }

  describe "::class_s" do
    it "replaces '+' with 'x'" do
      expect(subject.class_s("foo++")).to eq("Fooxx")
    end

    it "converts a string to PascalCase" do
      expect(subject.class_s("shell.fm")).to eq("ShellFm")
      expect(subject.class_s("s-lang")).to eq("SLang")
      expect(subject.class_s("pkg-config")).to eq("PkgConfig")
      expect(subject.class_s("foo_bar")).to eq("FooBar")
    end

    it "replaces '@' with 'AT'" do
      expect(subject.class_s("openssl@1.1")).to eq("OpensslAT11")
    end
  end

  describe "::factory" do
    before(:each) do
      formula_path.write formula_content
    end

    it "returns a Formula" do
      expect(subject.factory(formula_name)).to be_kind_of(Formula)
    end

    it "returns a Formula when given a fully qualified name" do
      expect(subject.factory("homebrew/core/#{formula_name}")).to be_kind_of(Formula)
    end

    it "raises an error if the Formula cannot be found" do
      expect {
        subject.factory("not_existed_formula")
      }.to raise_error(FormulaUnavailableError)
    end

    context "if the Formula has the wrong class" do
      let(:formula_name) { "giraffe" }
      let(:formula_content) do
        <<-EOS.undent
          class Wrong#{subject.class_s(formula_name)} < Formula
          end
        EOS
      end

      it "raises an error" do
        expect {
          subject.factory(formula_name)
        }.to raise_error(FormulaClassUnavailableError)
      end
    end

    it "returns a Formula when given a path" do
      expect(subject.factory(formula_path)).to be_kind_of(Formula)
    end

    it "returns a Formula when given a URL" do
      formula = subject.factory("file://#{formula_path}")
      expect(formula).to be_kind_of(Formula)
    end

    it "returns a Formula when given a bottle" do
      formula = subject.factory(bottle)
      expect(formula).to be_kind_of(Formula)
      expect(formula.local_bottle_path).to eq(bottle.realpath)
    end

    it "returns a Formula when given an alias" do
      alias_dir = CoreTap.instance.alias_dir
      alias_dir.mkpath
      alias_path = alias_dir/"foo"
      FileUtils.ln_s formula_path, alias_path
      result = subject.factory("foo")
      expect(result).to be_kind_of(Formula)
      expect(result.alias_path).to eq(alias_path.to_s)
    end

    context "with installed Formula" do
      let(:formula) { subject.factory(formula_path) }
      let(:installer) { FormulaInstaller.new(formula) }

      it "returns a Formula when given a rack" do
        installer.install

        f = subject.from_rack(formula.rack)
        expect(f).to be_kind_of(Formula)
        expect(f.build).to be_kind_of(Tab)
      end

      it "returns a Formula when given a Keg" do
        installer.install

        keg = Keg.new(formula.prefix)
        f = subject.from_keg(keg)
        expect(f).to be_kind_of(Formula)
        expect(f.build).to be_kind_of(Tab)
      end
    end

    context "from Tap" do
      let(:tap) { Tap.new("homebrew", "foo") }
      let(:formula_path) { tap.path/"#{formula_name}.rb" }

      it "returns a Formula when given a name" do
        expect(subject.factory(formula_name)).to be_kind_of(Formula)
      end

      it "returns a Formula from an Alias path" do
        alias_dir = tap.path/"Aliases"
        alias_dir.mkpath
        FileUtils.ln_s formula_path, alias_dir/"bar"
        expect(subject.factory("bar")).to be_kind_of(Formula)
      end

      it "raises an error when the Formula cannot be found" do
        expect {
          subject.factory("#{tap}/not_existed_formula")
        }.to raise_error(TapFormulaUnavailableError)
      end

      it "returns a Formula when given a fully qualified name" do
        expect(subject.factory("#{tap}/#{formula_name}")).to be_kind_of(Formula)
      end

      it "raises an error if a Formula is in multiple Taps" do
        begin
          another_tap = Tap.new("homebrew", "bar")
          (another_tap.path/"#{formula_name}.rb").write formula_content
          expect {
            subject.factory(formula_name)
          }.to raise_error(TapFormulaAmbiguityError)
        ensure
          another_tap.path.rmtree
        end
      end
    end
  end

  specify "::from_contents" do
    expect(subject.from_contents(formula_name, formula_path, formula_content)).to be_kind_of(Formula)
  end

  specify "::to_rack" do
    expect(subject.to_rack(formula_name)).to eq(HOMEBREW_CELLAR/formula_name)

    (HOMEBREW_CELLAR/formula_name).mkpath
    expect(subject.to_rack(formula_name)).to eq(HOMEBREW_CELLAR/formula_name)

    expect {
      subject.to_rack("a/b/#{formula_name}")
    }.to raise_error(TapFormulaUnavailableError)
  end

  describe "::find_with_priority" do
    let(:core_path) { CoreTap.new.formula_dir/"#{formula_name}.rb" }
    let(:tap) { Tap.new("homebrew", "foo") }
    let(:tap_path) { tap.path/"#{formula_name}.rb" }

    before(:each) do
      core_path.write formula_content
      tap_path.write formula_content
    end

    it "prioritizes core Formulae" do
      formula = subject.find_with_priority(formula_name)
      expect(formula).to be_kind_of(Formula)
      expect(formula.path).to eq(core_path)
    end

    it "prioritizes Formulae from pinned Taps" do
      begin
        tap.pin
        formula = subject.find_with_priority(formula_name)
        expect(formula).to be_kind_of(Formula)
        expect(formula.path).to eq(tap_path.realpath)
      ensure
        tap.pinned_symlink_path.parent.parent.rmtree
      end
    end
  end

  describe "::core_path" do
    it "returns the path to a Formula in the core tap" do
      name = "foo-bar"
      expect(subject.core_path(name))
        .to eq(Pathname.new("#{HOMEBREW_LIBRARY}/Taps/homebrew/homebrew-core/Formula/#{name}.rb"))
    end
  end
end
