cask 'version-latest' do
  version :latest
  sha256 :no_check

  url "file://#{TEST_FIXTURE_DIR}/cask/caffeines.zip"
  homepage 'http://example.com/local-caffeine'

  app 'Caffeine Mini.app'
  app 'Caffeine Pro.app'
end
