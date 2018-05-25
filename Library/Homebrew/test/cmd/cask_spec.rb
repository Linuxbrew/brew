describe "brew cask", :integration_test, :needs_macos, :needs_network do
  describe "list" do
    it "returns a list of installed Casks" do
      setup_remote_tap("homebrew/cask")

      expect { brew "cask", "list" }.to be_a_success
    end
  end
end
