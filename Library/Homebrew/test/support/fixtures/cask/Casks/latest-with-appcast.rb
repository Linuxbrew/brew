cask 'latest-with-appcast' do
  version :latest
  sha256 :no_check

  url "file://#{TEST_FIXTURE_DIR}/cask/caffeine.zip"
  appcast 'https://brew.sh/appcast.xml'
  homepage 'https://brew.sh/with-appcast'

  app 'Caffeine.app'
end
