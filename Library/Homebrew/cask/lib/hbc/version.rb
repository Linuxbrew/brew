module Hbc
  def self.full_version
    @full_version ||= begin
      <<~EOS
        Homebrew-Cask #{HOMEBREW_VERSION}
        #{Hbc.default_tap.full_name} #{Hbc.default_tap.version_string}
      EOS
    end
  end
end
