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

        begin
          expect(dir/".gnupg/pubring.kbx").to be_file
        rescue RSpec::Expectations::ExpectationNotMetError
          expect(dir/".gnupg/secring.gpg").to be_file
        end
      end
    end
  end
end
