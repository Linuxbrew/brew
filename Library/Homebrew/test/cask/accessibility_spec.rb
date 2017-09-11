# TODO: this test should be named after the corresponding class, once
#       that class is abstracted from installer.rb.
describe "Accessibility Access", :cask do
  let(:cask) { Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/with-accessibility-access.rb") }
  let(:fake_system_command) { class_double(Hbc::SystemCommand) }
  let(:installer) { Hbc::Installer.new(cask, command: fake_system_command) }

  before(:each) do
    allow(MacOS).to receive(:version).and_return(MacOS::Version.new(macos_version))
    allow(installer).to receive(:bundle_identifier).and_return("com.example.BasicCask")
  end

  context "on MacOS 10.8 and below" do
    let(:macos_version) { "10.8" }

    it "can enable accessibility access in macOS releases prior to Mavericks" do
      expect(fake_system_command).to receive(:run!).with(
        "/usr/bin/touch",
        args: [Hbc.pre_mavericks_accessibility_dotfile],
        sudo: true,
      )

      installer.enable_accessibility_access
    end

    it "warns about disabling accessibility access on old macOS releases" do
      expect {
        installer.disable_accessibility_access
      }.to output(/Warning: Accessibility access cannot be disabled automatically on this version of macOS\./).to_stderr
    end
  end

  context "on MacOS 10.9" do
    let(:macos_version) { "10.9" }

    it "can enable accessibility access" do
      expect(fake_system_command).to receive(:run!).with(
        "/usr/bin/sqlite3",
        args: [Hbc.tcc_db, "INSERT OR REPLACE INTO access VALUES('kTCCServiceAccessibility','com.example.BasicCask',0,1,1,NULL);"],
        sudo: true,
      )

      installer.enable_accessibility_access
    end

    it "can disable accessibility access" do
      expect(fake_system_command).to receive(:run!).with(
        "/usr/bin/sqlite3",
        args: [Hbc.tcc_db, "DELETE FROM access WHERE client='com.example.BasicCask';"],
        sudo: true,
      )

      installer.disable_accessibility_access
    end
  end

  context "on MacOS 10.12 and above" do
    let(:macos_version) { "10.12" }

    it "warns about enabling accessibility access on new macOS releases" do
      expect {
        expect {
          installer.enable_accessibility_access
        }.to output.to_stdout
      }.to output(/Warning: Accessibility access cannot be enabled automatically on this version of macOS\./).to_stderr
    end

    it "warns about disabling accessibility access on new macOS releases" do
      expect {
        installer.disable_accessibility_access
      }.to output(/Warning: Accessibility access cannot be disabled automatically on this version of macOS\./).to_stderr
    end
  end
end
