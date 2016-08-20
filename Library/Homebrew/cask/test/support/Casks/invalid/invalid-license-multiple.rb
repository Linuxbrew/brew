test_cask 'invalid-license-multiple' do
  version '2.61'
  sha256 'e44ffa103fbf83f55c8d0b1bea309a43b2880798dae8620b1ee8da5e1095ec68'

  url TestHelper.local_binary_url('transmission-2.61.dmg')
  homepage 'http://example.com/invalid-license-multiple'
  license :gpl
  license :gpl

  app 'Transmission.app'
end
