module Hbc
  module QualifiedToken
    def self.parse(arg)
      return nil unless arg.is_a?(String)
      return nil unless match = arg.downcase.match(HOMEBREW_TAP_CASK_REGEX)
      user, repo, token = match.captures
      odebug "[user, repo, token] might be [#{user}, #{repo}, #{token}]"
      [user, repo, token]
    end
  end
end
