require "open3"

describe "RuboCop" do
  context "when calling `rubocop` outside of the Homebrew environment" do
    before do
      ENV.keys.each do |key|
        ENV.delete(key) if key.start_with?("HOMEBREW_")
      end

      ENV["XDG_CACHE_HOME"] = "#{HOMEBREW_CACHE}/style"
    end

    it "loads all Formula cops without errors" do
      _, _, status = Open3.capture3("rubocop", TEST_FIXTURE_DIR/"testball.rb")
      expect(status).to be_a_success
    end
  end
end
