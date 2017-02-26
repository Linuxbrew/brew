describe "brew cask", :integration_test, :needs_macos, :needs_official_cmd_taps do
  describe "list" do
    it "returns a list of installed Casks" do
      setup_remote_tap("caskroom/cask")
      expect { brew "cask", "list" }.to be_a_success
    end
  end
end
