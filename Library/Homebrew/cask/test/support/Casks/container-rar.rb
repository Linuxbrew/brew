test_cask 'container-rar' do
  version '1.2.3'
  sha256 '419af7864c0e1f125515c49b08bd22e0f7de39f5285897c440fe03c714871763'

  url "file://#{TEST_FIXTURE_DIR}/cask/container.rar"
  homepage 'https://example.com/container-rar'

  depends_on formula: 'unar'

  app 'container'
end
