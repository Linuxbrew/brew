# TODO: this test should be named after the corresponding class, once
#       that class is abstracted from installer.rb
describe "Satisfy Dependencies and Requirements", :cask do
  subject {
    lambda do
      Cask::Installer.new(cask).install
    end
  }

  describe "depends_on cask" do
    context "when depends_on cask is cyclic" do
      let(:cask) { Cask::CaskLoader.load(cask_path("with-depends-on-cask-cyclic")) }

      it {
        expect(subject).to raise_error(
          Cask::CaskCyclicDependencyError,
          "Cask 'with-depends-on-cask-cyclic' includes cyclic dependencies "\
          "on other Casks: with-depends-on-cask-cyclic-helper",
        )
      }
    end

    context do
      let(:cask) { Cask::CaskLoader.load(cask_path("with-depends-on-cask")) }
      let(:dependency) { Cask::CaskLoader.load(cask.depends_on.cask.first) }

      it "installs the dependency of a Cask and the Cask itself" do
        expect(subject).not_to raise_error
        expect(cask).to be_installed
        expect(dependency).to be_installed
      end
    end
  end

  describe "depends_on macos" do
    context "given an array" do
      let(:cask) { Cask::CaskLoader.load(cask_path("with-depends-on-macos-array")) }

      it { is_expected.not_to raise_error }
    end

    context "given a comparison" do
      let(:cask) { Cask::CaskLoader.load(cask_path("with-depends-on-macos-comparison")) }

      it { is_expected.not_to raise_error }
    end

    context "given a string" do
      let(:cask) { Cask::CaskLoader.load(cask_path("with-depends-on-macos-string")) }

      it { is_expected.not_to raise_error }
    end

    context "given a symbol" do
      let(:cask) { Cask::CaskLoader.load(cask_path("with-depends-on-macos-symbol")) }

      it { is_expected.not_to raise_error }
    end

    context "when not satisfied" do
      let(:cask) { Cask::CaskLoader.load(cask_path("with-depends-on-macos-failure")) }

      it { is_expected.to raise_error(Cask::CaskError) }
    end
  end

  describe "depends_on arch" do
    context "when satisfied" do
      let(:cask) { Cask::CaskLoader.load(cask_path("with-depends-on-arch")) }

      it { is_expected.not_to raise_error }
    end
  end

  describe "depends_on x11" do
    before do
      allow(MacOS::X11).to receive(:installed?).and_return(x11_installed)
    end

    context "when satisfied" do
      let(:cask) { Cask::CaskLoader.load(cask_path("with-depends-on-x11")) }
      let(:x11_installed) { true }

      it { is_expected.not_to raise_error }
    end

    context "when not satisfied" do
      let(:cask) { Cask::CaskLoader.load(cask_path("with-depends-on-x11")) }
      let(:x11_installed) { false }

      it { is_expected.to raise_error(Cask::CaskX11DependencyError) }
    end

    context "when depends_on x11: false" do
      let(:cask) { Cask::CaskLoader.load(cask_path("with-depends-on-x11-false")) }
      let(:x11_installed) { false }

      it { is_expected.not_to raise_error }
    end
  end
end
