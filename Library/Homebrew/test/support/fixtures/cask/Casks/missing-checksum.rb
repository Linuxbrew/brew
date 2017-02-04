cask 'missing-checksum' do
  version '1.2.3'

  url "file://#{TEST_FIXTURE_DIR}/cask/caffeine.zip"
  homepage 'http://example.com/local-caffeine'

  app 'Caffeine.app'
end
