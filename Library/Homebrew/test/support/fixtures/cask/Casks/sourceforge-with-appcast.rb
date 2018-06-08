cask 'sourceforge-with-appcast' do
  version '1.2.3'

  url 'https://downloads.sourceforge.net/something/Something-1.2.3.dmg'
  appcast 'https://sourceforge.net/projects/something/rss'
  homepage 'https://sourceforge.net/projects/something/'
end
