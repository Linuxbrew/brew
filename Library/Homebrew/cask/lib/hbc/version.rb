module Hbc
  def self.full_version
    @full_version ||= begin
      <<-EOS.undent
        Homebrew-Cask #{HOMEBREW_VERSION}
        caskroom/homebrew-cask #{Hbc.default_tap.version_string}
      EOS
    end
  end
end
