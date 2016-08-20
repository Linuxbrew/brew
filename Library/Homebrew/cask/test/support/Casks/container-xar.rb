test_cask 'container-xar' do
  version '1.2.3'
  sha256 '5bb8e09a6fc630ebeaf266b1fd2d15e2ae7d32d7e4da6668a8093426fa1ba509'

  url TestHelper.local_binary_url('container.xar')
  homepage 'https://example.com/container-xar'

  app 'container'
end
