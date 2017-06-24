cask 'container-gpg' do
  version '1.2.3'
  sha256 :no_check

  url "file://#{TEST_FIXTURE_DIR}/cask/container.tar.xz.gpg"
  gpg :embedded, key_id: 'B0976E51E5C047AD0FD051294E402EBF7C3C6A71'

  homepage 'https://example.com/container-gpg'
  depends_on formula: 'gpg'

  app 'container'
end
