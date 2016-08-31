test_cask 'invalid-license-value' do
  version '2.61'
  sha256 'e44ffa103fbf83f55c8d0b1bea309a43b2880798dae8620b1ee8da5e1095ec68'

  url TestHelper.local_binary_url('transmission-2.61.dmg')
  homepage 'http://example.com/invalid-license-value'
  license :no_such_license

  app 'Transmission.app'
end
