require "test_helper"

# TODO: this test should be named after the corresponding class, once
#       that class is abstracted from installer.rb
describe "Satisfy Dependencies and Requirements" do
  # TODO: test that depends_on formula invokes Homebrew
  #
  # describe "depends_on formula" do
  #   it "" do
  #   end
  # end
  #

  describe "depends_on cask" do
    it "raises an exception when depends_on cask is cyclic" do
      dep_cask = Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/with-depends-on-cask-cyclic.rb")
      lambda {
        shutup do
          Hbc::Installer.new(dep_cask).install
        end
      }.must_raise(Hbc::CaskCyclicCaskDependencyError)
    end

    it "installs the dependency of a Cask and the Cask itself" do
      csk = Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/with-depends-on-cask.rb")
      dependency = Hbc.load(csk.depends_on.cask.first)
      shutup do
        Hbc::Installer.new(csk).install
      end

      csk.must_be :installed?
      dependency.must_be :installed?
    end
  end

  describe "depends_on macos" do
    it "understands depends_on macos: <array>" do
      macos_cask = Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/with-depends-on-macos-array.rb")
      shutup do
        Hbc::Installer.new(macos_cask).install
      end
    end

    it "understands depends_on macos: <comparison>" do
      macos_cask = Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/with-depends-on-macos-comparison.rb")
      shutup do
        Hbc::Installer.new(macos_cask).install
      end
    end

    it "understands depends_on macos: <string>" do
      macos_cask = Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/with-depends-on-macos-string.rb")
      shutup do
        Hbc::Installer.new(macos_cask).install
      end
    end

    it "understands depends_on macos: <symbol>" do
      macos_cask = Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/with-depends-on-macos-symbol.rb")
      shutup do
        Hbc::Installer.new(macos_cask).install
      end
    end

    it "raises an exception when depends_on macos is not satisfied" do
      macos_cask = Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/with-depends-on-macos-failure.rb")
      lambda {
        shutup do
          Hbc::Installer.new(macos_cask).install
        end
      }.must_raise(Hbc::CaskError)
    end
  end

  describe "depends_on arch" do
    it "succeeds when depends_on arch is satisfied" do
      arch_cask = Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/with-depends-on-arch.rb")
      shutup do
        Hbc::Installer.new(arch_cask).install
      end
    end
  end

  describe "depends_on x11" do
    it "succeeds when depends_on x11 is satisfied" do
      x11_cask = Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/with-depends-on-x11.rb")
      MacOS::X11.stubs(:installed?).returns(true)
      shutup do
        Hbc::Installer.new(x11_cask).install
      end
    end

    it "raises an exception when depends_on x11 is not satisfied" do
      x11_cask = Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/with-depends-on-x11.rb")
      MacOS::X11.stubs(:installed?).returns(false)
      lambda {
        shutup do
          Hbc::Installer.new(x11_cask).install
        end
      }.must_raise(Hbc::CaskX11DependencyError)
    end

    it "never raises when depends_on x11: false" do
      x11_cask = Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/with-depends-on-x11-false.rb")
      MacOS::X11.stubs(:installed?).returns(false)
      lambda do
        shutup do
          Hbc::Installer.new(x11_cask).install
        end
      end # won't raise
    end
  end
end
