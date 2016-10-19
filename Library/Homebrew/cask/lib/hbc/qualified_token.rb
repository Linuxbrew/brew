module Hbc
  module QualifiedToken
    def self.parse(arg)
      return nil unless arg.is_a?(String)
      return nil unless arg.downcase =~ HOMEBREW_TAP_CASK_REGEX
      # eg caskroom/cask/google-chrome
      # per https://github.com/Homebrew/brew/blob/master/docs/brew-tap.md
      user, repo, token = arg.downcase.split("/")
      odebug "[user, repo, token] might be [#{user}, #{repo}, #{token}]"
      [user, repo, token]
    end
  end
end
