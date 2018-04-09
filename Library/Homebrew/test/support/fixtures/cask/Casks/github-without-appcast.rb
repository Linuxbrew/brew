cask 'github-without-appcast' do
  version '1.0'
  sha256 'a69e7357bea014f4c14ac9699274f559086844ffa46563c4619bf1addfd72ad9'

  url "https://github.com/user/project/releases/download/#{version}/github.pkg"
  name 'github'
  homepage 'https://github.com/user/project'

  pkg 'github.pkg'

  uninstall pkgutil: 'com.github'
end
