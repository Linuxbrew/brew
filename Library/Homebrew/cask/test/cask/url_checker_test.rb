require "test_helper"

describe Hbc::UrlChecker do
  describe "request processing" do
    let(:cask) { Hbc.load("basic-cask") }
    let(:checker) { Hbc::UrlChecker.new(cask) }
    let(:with_stubbed_fetcher) {
      lambda { |&block|
        Hbc::Fetcher.stub(:head, response) do
          checker.run
          instance_eval(&block)
        end
      }
    }

    describe "with an empty response" do
      let(:response) { "" }

      it "adds an error" do
        with_stubbed_fetcher.call do
          expect(checker.errors).must_include("timeout while requesting #{cask.url}")
        end
      end
    end

    describe "with a valid http response" do
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
        with_stubbed_fetcher.call do
          expect(checker.errors).must_be_empty
          expect(checker.response_status).must_equal("HTTP/1.1 200 OK")
          expect(checker.headers).must_equal(
            "Content-Type"   => "application/x-apple-diskimage",
            "ETag"           => '"b4208f3e84967be4b078ecaa03fba941"',
            "Content-Length" => "23726161",
            "Last-Modified"  => "Sun, 12 Aug 2012 21:17:21 GMT"
          )
        end
      end
    end
  end
end
