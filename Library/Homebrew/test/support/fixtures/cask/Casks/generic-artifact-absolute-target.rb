cask 'generic-artifact-absolute-target' do
  artifact 'Caffeine.app', target: "#{Hbc::Config.global.appdir}/Caffeine.app"
end
