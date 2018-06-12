cask 'latest-with-appcast' do
  version :latest
  sha256 :no_check

  url "file://#{TEST_FIXTURE_DIR}/cask/caffeine.zip"
  appcast 'http://example.com/appcast.xml'
  homepage 'http://example.com/with-appcast'

  app 'Caffeine.app'
end
