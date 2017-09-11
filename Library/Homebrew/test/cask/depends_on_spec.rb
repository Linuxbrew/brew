# TODO: this test should be named after the corresponding class, once
#       that class is abstracted from installer.rb
describe "Satisfy Dependencies and Requirements", :cask do
  subject {
    lambda do
      Hbc::Installer.new(cask).install
    end
  }

  describe "depends_on cask" do
    context "when depends_on cask is cyclic" do
      let(:cask) { Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/with-depends-on-cask-cyclic.rb") }
      it { is_expected.to raise_error(Hbc::CaskCyclicDependencyError) }
    end

    context do
      let(:cask) { Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/with-depends-on-cask.rb") }
      let(:dependency) { Hbc::CaskLoader.load(cask.depends_on.cask.first) }

      it "installs the dependency of a Cask and the Cask itself" do
        expect(subject).not_to raise_error
        expect(cask).to be_installed
        expect(dependency).to be_installed
      end
    end
  end

  describe "depends_on macos" do
    context "given an array" do
      let(:cask) { Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/with-depends-on-macos-array.rb") }
      it { is_expected.not_to raise_error }
    end

    context "given a comparisson" do
      let(:cask) { Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/with-depends-on-macos-comparison.rb") }
      it { is_expected.not_to raise_error }
    end

    context "given a string" do
      let(:cask) { Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/with-depends-on-macos-string.rb") }
      it { is_expected.not_to raise_error }
    end

    context "given a symbol" do
      let(:cask) { Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/with-depends-on-macos-symbol.rb") }
      it { is_expected.not_to raise_error }
    end

    context "when not satisfied" do
      let(:cask) { Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/with-depends-on-macos-failure.rb") }
      it { is_expected.to raise_error(Hbc::CaskError) }
    end
  end

  describe "depends_on arch" do
    context "when satisfied" do
      let(:cask) { Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/with-depends-on-arch.rb") }
      it { is_expected.not_to raise_error }
    end
  end

  describe "depends_on x11" do
    before(:each) do
      allow(MacOS::X11).to receive(:installed?).and_return(x11_installed)
    end

    context "when satisfied" do
      let(:cask) { Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/with-depends-on-x11.rb") }
      let(:x11_installed) { true }

      it { is_expected.not_to raise_error }
    end

    context "when not satisfied" do
      let(:cask) { Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/with-depends-on-x11.rb") }
      let(:x11_installed) { false }

      it { is_expected.to raise_error(Hbc::CaskX11DependencyError) }
    end

    context "when depends_on x11: false" do
      let(:cask) { Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/with-depends-on-x11-false.rb") }
      let(:x11_installed) { false }

      it { is_expected.not_to raise_error }
    end
  end
end
