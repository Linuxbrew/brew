cask 'sourceforge-with-appcast' do
  version '1.2.3'

  url 'https://downloads.sourceforge.net/something/Something-1.2.3.dmg'
  appcast 'https://sourceforge.net/projects/something/rss',
          checkpoint: '407fb59baa4b9eb7651d9243b89c30b7481590947ef78bd5a4c24f5810f56531'
  homepage 'https://sourceforge.net/projects/something/'
end
