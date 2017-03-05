require "hbc/system_command"

describe Hbc::SystemCommand::Result, :cask do
  describe "::_parse_plist" do
    subject { described_class._parse_plist(command, input) }
    let(:command) { Hbc::SystemCommand.new("/usr/bin/true", {}) }
    let(:plist) {
      <<-EOS.undent
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
          <key>system-entities</key>
          <array>
            <dict>
              <key>content-hint</key>
              <string>Apple_partition_map</string>
              <key>dev-entry</key>
              <string>/dev/disk3s1</string>
              <key>potentially-mountable</key>
              <false/>
              <key>unmapped-content-hint</key>
              <string>Apple_partition_map</string>
            </dict>
            <dict>
              <key>content-hint</key>
              <string>Apple_partition_scheme</string>
              <key>dev-entry</key>
              <string>/dev/disk3</string>
              <key>potentially-mountable</key>
              <false/>
              <key>unmapped-content-hint</key>
              <string>Apple_partition_scheme</string>
            </dict>
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

    context "when output contains garbage" do
      let(:input) {
        <<-EOS.undent
          Hello there! I am in no way XML am I?!?!

            That's a little silly... you were expexting XML here!

          What is a parser to do?

          Hopefully <not> explode!

          #{plist}
        EOS
      }

      it "ignores garbage before xml" do
        expect(subject.keys).to eq(["system-entities"])
        expect(subject["system-entities"].length).to eq(3)
      end
    end

    context "given a hdiutil output as input" do
      let(:input) { plist }

      it "successfully parses it" do
        expect(subject.keys).to eq(["system-entities"])
        expect(subject["system-entities"].length).to eq(3)
        expect(subject["system-entities"].map { |e| e["dev-entry"] })
          .to eq(["/dev/disk3s1", "/dev/disk3", "/dev/disk3s2"])
      end
    end

    context "given an empty input" do
      let(:input) { "" }

      it "raises an error" do
        expect { subject }.to raise_error(Hbc::CaskError, /Empty plist input/)
      end
    end
  end
end
