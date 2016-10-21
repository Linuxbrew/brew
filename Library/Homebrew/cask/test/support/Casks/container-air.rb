test_cask 'container-air' do
  version '0.1'
  sha256 '554472e163f8a028629b12b468e29acda9f16b223dff74fcd218bba73cc2365a'

  url "file://#{TEST_FIXTURE_DIR}/cask/container.air"
  homepage 'https://example.com/container-air'

  app 'container.app'
end
