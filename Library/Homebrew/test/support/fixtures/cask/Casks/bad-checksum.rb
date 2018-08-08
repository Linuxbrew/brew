cask 'bad-checksum' do
  version '1.2.3'
  sha256 'badbadbadbadbadbadbadbadbadbadbadbadbadbadbadbadbadbadbadbadbadb'

  url "file://#{TEST_FIXTURE_DIR}/cask/caffeine.zip"
  homepage 'https://example.com/local-caffeine'

  app 'Caffeine.app'
end
