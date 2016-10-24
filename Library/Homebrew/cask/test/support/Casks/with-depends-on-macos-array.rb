test_cask 'with-depends-on-macos-array' do
  version '1.2.3'
  sha256 '67cdb8a02803ef37fdbf7e0be205863172e41a561ca446cd84f0d7ab35a99d94'

  url "file://#{TEST_FIXTURE_DIR}/cask/caffeine.zip"
  homepage 'http://example.com/with-depends-on-macos-array'

  # since all OS releases are included, this should always pass
  depends_on macos: ['10.4', '10.5', '10.6', '10.7', '10.8', '10.9', '10.10', MacOS.version.to_s]

  app 'Caffeine.app'
end
