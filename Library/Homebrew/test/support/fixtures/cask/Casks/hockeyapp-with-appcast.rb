cask 'hockeyapp-with-appcast' do
  version '1.0,123'
  sha256 'a69e7357bea014f4c14ac9699274f559086844ffa46563c4619bf1addfd72ad9'

  # rink.hockeyapp.net/api/2/apps/67503a7926431872c4b6c1549f5bd6b1 was verified as official when first introduced to the cask
  url "https://rink.hockeyapp.net/api/2/apps/67503a7926431872c4b6c1549f5bd6b1/app_versions/#{version.after_comma}?format=zip"
  appcast 'https://rink.hockeyapp.net/api/2/apps/67503a7926431872c4b6c1549f5bd6b1'
  name 'HockeyApp'
  homepage 'https://www.example.com/'

  app 'HockeyApp.app'
end
