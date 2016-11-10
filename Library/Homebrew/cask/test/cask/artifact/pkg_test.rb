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
      pkg = Hbc::Artifact::Pkg.new(@cask,
                                   command: Hbc::FakeSystemCommand)

      Hbc::FakeSystemCommand.expects_command(["/usr/bin/sudo", "-E", "--", "/usr/sbin/installer", "-pkg", @cask.staged_path.join("MyFancyPkg", "Fancy.pkg"), "-target", "/", "-applyChoiceChangesXML", @cask.staged_path.join("Choices.xml")])

      shutup do
        pkg.install_phase
      end

      IO.read(@cask.staged_path.join("Choices.xml")).must_equal <<-EOS.undent
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <array>
        	<dict>
        		<key>attributeSetting</key>
        		<integer>1</integer>
        		<key>choiceAttribute</key>
        		<string>selected</string>
        		<key>choiceIdentifier</key>
        		<string>choice1</string>
        	</dict>
        </array>
        </plist>
      EOS
    end
  end
end
