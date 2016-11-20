require "test_helper"

describe Hbc::Artifact::Pkg do
  before do
    @cask = Hbc.load("with-installable")
    shutup do
      TestHelper.install_without_artifacts(@cask)
    end
  end

  describe "install_phase" do
    it "runs the system installer on the specified pkgs" do
      pkg = Hbc::Artifact::Pkg.new(@cask,
                                   command: Hbc::FakeSystemCommand)

      Hbc::FakeSystemCommand.expects_command(["/usr/bin/sudo", "-E", "--", "/usr/sbin/installer", "-pkg", @cask.staged_path.join("MyFancyPkg", "Fancy.pkg"), "-target", "/"])

      shutup do
        pkg.install_phase
      end
    end
  end

  describe "uninstall_phase" do
    it "does nothing, because the uninstall_phase method is a no-op" do
      pkg = Hbc::Artifact::Pkg.new(@cask,
                                   command: Hbc::FakeSystemCommand)
      shutup do
        pkg.uninstall_phase
      end
    end
  end

  describe "choices" do
    before do
      @cask = Hbc.load("with-choices")
      shutup do
        TestHelper.install_without_artifacts(@cask)
      end
    end

    it "passes the choice changes xml to the system installer" do
      pkg = Hbc::Artifact::Pkg.new(@cask, command: Hbc::FakeSystemCommand)

      file = mock
      file.expects(:write).with <<-EOS.undent
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <array>
        \t<dict>
        \t\t<key>attributeSetting</key>
        \t\t<integer>1</integer>
        \t\t<key>choiceAttribute</key>
        \t\t<string>selected</string>
        \t\t<key>choiceIdentifier</key>
        \t\t<string>choice1</string>
        \t</dict>
        </array>
        </plist>
      EOS
      file.stubs path: Pathname.new("/tmp/choices.xml")
      file.expects(:close).with true
      Tempfile.expects(:new).returns file

      Hbc::FakeSystemCommand.expects_command(["/usr/bin/sudo", "-E", "--", "/usr/sbin/installer", "-pkg", @cask.staged_path.join("MyFancyPkg", "Fancy.pkg"), "-target", "/", "-applyChoiceChangesXML", @cask.staged_path.join("/tmp/choices.xml")])

      shutup do
        pkg.install_phase
      end
    end
  end
end
