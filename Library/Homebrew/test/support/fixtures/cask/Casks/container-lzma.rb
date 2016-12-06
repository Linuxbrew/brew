test_cask 'container-lzma' do
  version '1.2.3'
  sha256 '9d7edb32d02ab9bd9749a5bde8756595ea4cfcb1da02ca11c30fb591d4c1ed85'

  url "file://#{TEST_FIXTURE_DIR}/cask/container.lzma"
  homepage 'https://example.com/container-lzma'

  depends_on formula: 'lzma'

  app 'container-lzma--1.2.3'
end
