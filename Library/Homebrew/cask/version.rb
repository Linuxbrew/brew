module Hbc
  def self.full_version
    @full_version ||= begin
      <<~EOS
        Homebrew Cask #{HOMEBREW_VERSION}
        #{Tap.default_cask_tap.full_name} #{Tap.default_cask_tap.version_string}
      EOS
    end
  end
end
