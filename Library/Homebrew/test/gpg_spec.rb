require "gpg"

describe Gpg do
  subject { described_class }

  describe "::create_test_key" do
    it "creates a test key in the home directory" do
      skip "GPG Unavailable" unless subject.available?

      Dir.mktmpdir do |dir|
        ENV["HOME"] = dir
        dir = Pathname.new(dir)

        shutup do
          subject.create_test_key(dir)
        end
        expect(dir/".gnupg/secring.gpg").to exist
      end
    end
  end
end
