cask 'with-languages' do
  version '1.2.3'

  language "zh" do
    sha256 "abc123"
    "zh-CN"
  end

  language "en-US", default: true do
    sha256 "xyz789"
    "en-US"
  end

  url "file://#{TEST_FIXTURE_DIR}/cask/caffeine.zip"
  homepage 'https://example.com/local-caffeine'

  app 'Caffeine.app'
end
