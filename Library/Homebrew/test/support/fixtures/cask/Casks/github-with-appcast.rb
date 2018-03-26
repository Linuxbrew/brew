cask 'github-with-appcast' do
  version '1.0'
  sha256 'a69e7357bea014f4c14ac9699274f559086844ffa46563c4619bf1addfd72ad9'

  url "https://github.com/user/project/releases/download/#{version}/github.pkg"
  appcast 'https://github.com/user/project/releases.atom',
          checkpoint: '56d1707d3065bf0c75d75d7738571285273b7bf366d8f0f5a53eb8b457ad2453'
  name 'github'
  homepage 'https://github.com/user/project'

  pkg 'github.pkg'

  uninstall pkgutil: 'com.github'
end
