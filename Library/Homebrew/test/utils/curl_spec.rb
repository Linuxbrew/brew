require "utils/curl"

describe "curl" do
  describe "curl_args" do
    it "returns -q as the first argument" do
      # -q must be the first argument according to "man curl"
      expect(curl_args("foo")[1]).to eq("-q")
    end
  end
end
