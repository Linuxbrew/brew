describe Hbc::SystemCommand::Result do
  describe "::_parse_plist" do
    let(:command) { Hbc::SystemCommand.new("/usr/bin/true", {}) }
    let(:hdiutil_output) {
      <<-EOS.undent
        Hello there! I am in no way XML am I?!?!

          That's a little silly... you were expexting XML here!

        What is a parser to do?

        Hopefully <not> explode!

        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
          <key>system-entities</key>
          <array>
            <dict>
              <key>content-hint</key>
              <string>Apple_HFS</string>
              <key>dev-entry</key>
              <string>/dev/disk3s2</string>
              <key>mount-point</key>
              <string>/private/tmp/dmg.BhfS2g</string>
              <key>potentially-mountable</key>
              <true/>
              <key>unmapped-content-hint</key>
              <string>Apple_HFS</string>
              <key>volume-kind</key>
              <string>hfs</string>
            </dict>
          </array>
        </dict>
        </plist>
      EOS
    }

    it "ignores garbage output before xml starts" do
      parsed = described_class._parse_plist(command, hdiutil_output)

      expect(parsed.keys).to eq(["system-entities"])
      expect(parsed["system-entities"].length).to eq(1)
    end
  end
end
