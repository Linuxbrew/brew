test_cask 'with-depends-on-macos-failure' do
  version '1.2.3'
  sha256 '67cdb8a02803ef37fdbf7e0be205863172e41a561ca446cd84f0d7ab35a99d94'

  url "file://#{TEST_FIXTURE_DIR}/cask/caffeine.zip"
  homepage 'http://example.com/with-depends-on-macos-failure'

  # guarantee a mismatched release
  depends_on macos: MacOS.version.to_s == '10.4' ? '10.5' : '10.4'

  app 'Caffeine.app'
end
