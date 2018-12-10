cask 'latest-with-auto-updates' do
  version :latest
  sha256 :no_check

  url "file://#{TEST_FIXTURE_DIR}/cask/caffeine.zip"
  homepage 'https://brew.sh/latest-with-auto-updates'

  auto_updates true

  app 'Caffeine.app'
end
