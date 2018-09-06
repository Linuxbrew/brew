shared_examples "a command that requires a Cask token" do
  context "when no Cask is specified" do
    it "raises an exception " do
      expect {
        described_class.run
      }.to raise_error(Cask::CaskUnspecifiedError, "This command requires a Cask token.")
    end
  end
end
