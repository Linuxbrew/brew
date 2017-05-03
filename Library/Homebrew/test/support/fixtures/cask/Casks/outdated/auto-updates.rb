cask 'auto-updates' do
  version '2.57'
  sha256 'e44ffa103fbf83f55c8d0b1bea309a43b2880798dae8620b1ee8da5e1095ec68'

  url "file://#{TEST_FIXTURE_DIR}/cask/transmission-2.61.dmg"
  homepage 'http://example.com/auto-updates'

  auto_updates true

  app 'Transmission.app'
end
