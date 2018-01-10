require "utils/popen"

describe Utils do
  describe "::popen_read" do
    it "reads the standard output of a given command" do
      expect(subject.popen_read("sh", "-c", "echo success").chomp).to eq("success")
      expect($CHILD_STATUS).to be_a_success
    end

    it "can be given a block to manually read from the pipe" do
      expect(
        subject.popen_read("sh", "-c", "echo success") do |pipe|
          pipe.read.chomp
        end,
      ).to eq("success")
      expect($CHILD_STATUS).to be_a_success
    end

    it "fails when the command does not exist" do
      expect(subject.popen_read("./nonexistent", err: :out))
        .to eq("brew: command not found: ./nonexistent\n")
      expect($CHILD_STATUS).to be_a_failure
    end
  end

  describe "::popen_write" do
    it "with supports writing to a command's standard input" do
      subject.popen_write("grep", "-q", "success") do |pipe|
        pipe.write("success\n")
      end
      expect($CHILD_STATUS).to be_a_success
    end
  end
end
