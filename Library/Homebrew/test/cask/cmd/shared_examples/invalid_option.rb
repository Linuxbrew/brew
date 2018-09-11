shared_examples "a command that handles invalid options" do
  context "when an invalid option is specified" do
    it "raises an exception when no Cask is specified" do
      expect {
        described_class.run("--not-a-valid-option")
      }.to raise_error("invalid option: --not-a-valid-option")
    end

    it "raises an exception when a Cask is specified" do
      expect {
        described_class.run("--not-a-valid-option", "basic-cask")
      }.to raise_error("invalid option: --not-a-valid-option")
    end
  end
end
