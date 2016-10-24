require "test_helper"

# TODO: this test should be named after the corresponding class, once
#       that class is abstracted from installer.rb.
describe "Accessibility Access" do
  let(:cask) { Hbc.load("with-accessibility-access") }
  let(:with_fake_command) { { command: Hbc::FakeSystemCommand } }
  let(:installer) { Hbc::Installer.new(cask, with_fake_command) }

  describe "install" do
    it "can enable accessibility access" do
      MacOS.stub :version, MacOS::Version.new("10.9") do
        installer.stub :bundle_identifier, "com.example.BasicCask" do
          Hbc::FakeSystemCommand.expects_command(
            ["/usr/bin/sudo", "-E", "--", "/usr/bin/sqlite3", Hbc.tcc_db, "INSERT OR REPLACE INTO access VALUES('kTCCServiceAccessibility','com.example.BasicCask',0,1,1,NULL);"]
          )
          shutup do
            installer.enable_accessibility_access
          end
        end
      end
    end

    it "can enable accessibility access in macOS releases prior to Mavericks" do
      MacOS.stub :version, MacOS::Version.new("10.8") do
        Hbc::FakeSystemCommand.expects_command(
          ["/usr/bin/sudo", "-E", "--", "/usr/bin/touch", Hbc.pre_mavericks_accessibility_dotfile]
        )
        shutup do
          installer.enable_accessibility_access
        end
      end
    end

    it "warns about enabling accessibility access on new macOS releases" do
      MacOS.stub :version, MacOS::Version.new("10.12") do
        installer.stub :bundle_identifier, "com.example.BasicCask" do
          capture_io { installer.enable_accessibility_access }[1]
            .must_match("Warning: Accessibility access cannot be enabled automatically on this version of macOS.")
        end
      end
    end
  end

  describe "uninstall" do
    it "can disable accessibility access" do
      MacOS.stub :version, MacOS::Version.new("10.9") do
        installer.stub :bundle_identifier, "com.example.BasicCask" do
          Hbc::FakeSystemCommand.expects_command(
            ["/usr/bin/sudo", "-E", "--", "/usr/bin/sqlite3", Hbc.tcc_db, "DELETE FROM access WHERE client='com.example.BasicCask';"]
          )
          shutup do
            installer.disable_accessibility_access
          end
        end
      end
    end

    it "warns about disabling accessibility access on old macOS releases" do
      MacOS.stub :version, MacOS::Version.new("10.8") do
        installer.stub :bundle_identifier, "com.example.BasicCask" do
          capture_io { installer.disable_accessibility_access }[1]
            .must_match("Warning: Accessibility access cannot be disabled automatically on this version of macOS.")
        end
      end
    end

    it "warns about disabling accessibility access on new macOS releases" do
      MacOS.stub :version, MacOS::Version.new("10.12") do
        installer.stub :bundle_identifier, "com.example.BasicCask" do
          capture_io { installer.disable_accessibility_access }[1]
            .must_match("Warning: Accessibility access cannot be disabled automatically on this version of macOS.")
        end
      end
    end
  end
end
