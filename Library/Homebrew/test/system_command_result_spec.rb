require "system_command"

describe SystemCommand::Result do
  describe "#to_ary" do
    let(:output) {
      [
        [:stdout, "output"],
        [:stderr, "error"],
      ]
    }
    subject(:result) {
      described_class.new([], output, instance_double(Process::Status, exitstatus: 0, success?: true))
    }

    it "can be destructed like `Open3.capture3`" do
      out, err, status = result

      expect(out).to eq "output"
      expect(err).to eq "error"
      expect(status).to be_a_success
    end
  end

  describe "#plist" do
    subject {
      described_class.new(command, [[:stdout, stdout]], instance_double(Process::Status, exitstatus: 0)).plist
    }

    let(:command) { ["true"] }
    let(:garbage) {
      <<~EOS
        Hello there! I am in no way XML am I?!?!

          That's a little silly... you were expecting XML here!

        What is a parser to do?

        Hopefully <not> explode!
      EOS
    }
    let(:plist) {
      <<~XML
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
      XML
    }

    context "when stdout contains garbage before XML" do
      let(:stdout) {
        <<~EOS
          #{garbage}
          #{plist}
        EOS
      }

      it "ignores garbage" do
        expect(subject["system-entities"].length).to eq(3)
      end

      context "when verbose" do
        before(:each) do
          allow(ARGV).to receive(:verbose?).and_return(true)
        end

        it "warns about garbage" do
          expect { subject }
            .to output(a_string_containing(garbage)).to_stderr
        end
      end
    end

    context "when stdout contains garbage after XML" do
      let(:stdout) {
        <<~EOS
          #{plist}
          #{garbage}
        EOS
      }

      it "ignores garbage" do
        expect(subject["system-entities"].length).to eq(3)
      end

      context "when verbose" do
        before(:each) do
          allow(ARGV).to receive(:verbose?).and_return(true)
        end

        it "warns about garbage" do
          expect { subject }
            .to output(a_string_containing(garbage)).to_stderr
        end
      end
    end

    context "given a hdiutil stdout" do
      let(:stdout) { plist }

      it "successfully parses it" do
        expect(subject.keys).to eq(["system-entities"])
        expect(subject["system-entities"].length).to eq(3)
        expect(subject["system-entities"].map { |e| e["dev-entry"] })
          .to eq(["/dev/disk3s1", "/dev/disk3", "/dev/disk3s2"])
      end
    end

    context "when the stdout of the command is empty" do
      let(:stdout) { "" }

      it "returns nil" do
        expect(subject).to be nil
      end
    end
  end
end
