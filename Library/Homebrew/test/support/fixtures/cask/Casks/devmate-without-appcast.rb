cask 'devmate-without-appcast' do
  version '1.0'
  sha256 'a69e7357bea014f4c14ac9699274f559086844ffa46563c4619bf1addfd72ad9'

  # dl.devmate.com/com.my.fancyapp was verified as official when first introduced to the cask
  url "https://dl.devmate.com/com.my.fancyapp/app_#{version}.zip"
  name 'DevMate'
  homepage 'https://www.brew.sh/'

  app 'DevMate.app'
end
