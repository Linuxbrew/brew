cask 'latest-with-appcast' do
  version :latest
  sha256 :no_check

  url "file://#{TEST_FIXTURE_DIR}/cask/caffeine.zip"
  appcast 'https://example.com/appcast.xml'
  homepage 'https://example.com/with-appcast'

  app 'Caffeine.app'
end
