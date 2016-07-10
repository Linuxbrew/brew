require "requirement"

class TuntapRequirement < Requirement
  fatal true
  default_formula "tuntap"
  cask "tuntap"
  satisfy(:build_env => false) { self.class.binary_tuntap_installed? || Formula["tuntap"].installed? }

  def self.binary_tuntap_installed?
    %w[
      /Library/Extensions/tun.kext
      /Library/Extensions/tap.kext
      /Library/LaunchDaemons/net.sf.tuntaposx.tun.plist
      /Library/LaunchDaemons/net.sf.tuntaposx.tap.plist
    ].all? { |file| File.exist?(file) }
  end
end
