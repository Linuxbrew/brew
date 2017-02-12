require "spec_helper"

describe Hbc::UrlChecker do
  describe "request processing" do
    let(:cask) { Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/basic-cask.rb") }
    let(:checker) { Hbc::UrlChecker.new(cask) }

    before(:each) do
      allow(Hbc::Fetcher).to receive(:head).and_return(response)
      checker.run
    end

    context "with an empty response" do
      let(:response) { "" }

      it "adds an error" do
        expect(checker.errors).to include("timeout while requesting #{cask.url}")
      end
    end

    context "with a valid http response" do
      let(:response) {
        <<-EOS.undent
          HTTP/1.1 200 OK
          Content-Type: application/x-apple-diskimage
          ETag: "b4208f3e84967be4b078ecaa03fba941"
          Content-Length: 23726161
          Last-Modified: Sun, 12 Aug 2012 21:17:21 GMT
        EOS
      }

      it "properly populates the response code and headers" do
        expect(checker.errors).to be_empty
        expect(checker.response_status).to eq("HTTP/1.1 200 OK")
        expect(checker.headers).to eq(
          "Content-Type"   => "application/x-apple-diskimage",
          "ETag"           => '"b4208f3e84967be4b078ecaa03fba941"',
          "Content-Length" => "23726161",
          "Last-Modified"  => "Sun, 12 Aug 2012 21:17:21 GMT",
        )
      end
    end
  end
end
