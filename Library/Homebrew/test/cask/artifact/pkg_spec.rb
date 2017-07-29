describe Hbc::Artifact::Pkg, :cask do
  let(:cask) { Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/with-installable.rb") }
  let(:fake_system_command) { class_double(Hbc::SystemCommand) }

  before(:each) do
    InstallHelper.install_without_artifacts(cask)
  end

  describe "install_phase" do
    it "runs the system installer on the specified pkgs" do
      pkg = Hbc::Artifact::Pkg.new(cask, command: fake_system_command)

      expect(fake_system_command).to receive(:run!).with(
        "/usr/sbin/installer",
        args: ["-pkg", cask.staged_path.join("MyFancyPkg", "Fancy.pkg"), "-target", "/"],
        sudo: true,
        print_stdout: true,
      )

      pkg.install_phase
    end
  end

  describe "choices" do
    let(:cask) { Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/with-choices.rb") }

    it "passes the choice changes xml to the system installer" do
      pkg = Hbc::Artifact::Pkg.new(cask, command: fake_system_command)

      file = double(path: Pathname.new("/tmp/choices.xml"))

      expect(file).to receive(:write).with(<<-EOS.undent)
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

      expect(file).to receive(:close)
      expect(file).to receive(:unlink)
      expect(Tempfile).to receive(:open).and_yield(file)

      expect(fake_system_command).to receive(:run!).with(
        "/usr/sbin/installer",
        args: ["-pkg", cask.staged_path.join("MyFancyPkg", "Fancy.pkg"), "-target", "/", "-applyChoiceChangesXML", cask.staged_path.join("/tmp/choices.xml")],
        sudo: true,
        print_stdout: true,
      )

      pkg.install_phase
    end
  end
end
