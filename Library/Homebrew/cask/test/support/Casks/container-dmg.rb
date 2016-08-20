test_cask 'container-dmg' do
  version '1.2.3'
  sha256 '74d89d4fa5cef175cf43666ce11fefa3741aa1522114042ac75e656be37141a1'

  url TestHelper.local_binary_url('container.dmg')
  homepage 'https://example.com/container-dmg'

  app 'container'
end
