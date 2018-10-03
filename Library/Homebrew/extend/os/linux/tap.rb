class CoreTap < Tap
  def default_remote
    if ENV["HOMEBREW_FORCE_HOMEBREW_ORG"]
      "https://github.com/Homebrew/homebrew-core".freeze
    else
      "https://github.com/Linuxbrew/homebrew-core".freeze
    end
  end
end
