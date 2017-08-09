require "lock_file"

describe LockFile do
  subject { described_class.new("foo") }

  describe "#lock" do
    it "does not raise an error when already locked" do
      subject.lock

      expect { subject.lock }.not_to raise_error
    end

    it "raises an error if a lock already exists" do
      subject.lock

      expect {
        described_class.new("foo").lock
      }.to raise_error(OperationInProgressError)
    end
  end

  describe "#unlock" do
    it "does not raise an error when already unlocked" do
      expect { subject.unlock }.not_to raise_error
    end

    it "unlocks when locked" do
      subject.lock
      subject.unlock

      expect { described_class.new("foo").lock }.not_to raise_error
    end
  end
end
