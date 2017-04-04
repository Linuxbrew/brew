require "gpg"

describe Gpg do
  subject { described_class }

  describe "::create_test_key" do
    it "creates a test key in the home directory" do
      skip "GPG Unavailable" unless subject.available?

      mktmpdir do |dir|
        ENV["HOME"] = dir

        shutup do
          subject.create_test_key(dir)
          gpg = subject::GPG_EXECUTABLE
          @version = Utils.popen_read(gpg, "--version")[/\d\.\d/, 0]
        end

        if @version.to_s.start_with?("2.1")
          expect(dir/".gnupg/pubring.kbx").to be_file
        else
          expect(dir/".gnupg/secring.gpg").to be_file
        end
      end
    end
  end
end
