test_cask 'container-cab' do
  version '1.2.3'
  sha256 'c267f5cebb14814c8e612a8b7d2bda02aec913f869509b6f1d3883427c0f552b'

  url TestHelper.local_binary_url('container.cab')
  homepage 'https://example.com/container-cab'

  depends_on formula: 'cabextract'

  app 'cabcontainer/Application.app'
end
