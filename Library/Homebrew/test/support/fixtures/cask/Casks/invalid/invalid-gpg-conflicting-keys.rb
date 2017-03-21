cask 'invalid-gpg-conflicting-keys' do
  version '1.2.3'
  sha256 '67cdb8a02803ef37fdbf7e0be205863172e41a561ca446cd84f0d7ab35a99d94'

  url "file://#{TEST_FIXTURE_DIR}/cask/caffeine.zip"
  homepage 'http://example.com/invalid-gpg-conflicting-keys'
  gpg 'http://example.com/gpg-signature.asc',
      key_id:  '01234567',
      key_url: 'http://example.com/gpg-key-url'

  app 'Caffeine.app'
end
