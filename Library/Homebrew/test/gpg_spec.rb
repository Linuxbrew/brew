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
        end

        if subject.version == Version.create("2.0")
          expect(dir/".gnupg/secring.gpg").to be_a_file
        else
          expect(dir/".gnupg/pubring.kbx").to be_a_file
        end
      end
    end
  end
end
