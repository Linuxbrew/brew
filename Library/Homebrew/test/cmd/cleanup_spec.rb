describe "brew cleanup", :integration_test do
  describe "--prune=all" do
    it "removes all files in Homebrew's cache" do
      (HOMEBREW_CACHE/"test").write "test"

      expect { brew "cleanup", "--prune=all" }
        .to output(%r{#{Regexp.escape(HOMEBREW_CACHE)}/test}).to_stdout
        .and not_to_output.to_stderr
        .and be_a_success
    end
  end
end
