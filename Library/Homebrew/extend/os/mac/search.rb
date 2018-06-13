require "hbc/cask"
require "hbc/cask_loader"

module Homebrew
  module Search
    def search_casks(string_or_regex)
      if string_or_regex.is_a?(String) && string_or_regex.match?(HOMEBREW_TAP_CASK_REGEX)
        return begin
          [Hbc::CaskLoader.load(string_or_regex).token]
        rescue Hbc::CaskUnavailableError
          []
        end
      end

      results = Hbc::Cask.search(string_or_regex, &:token).sort_by(&:token)

      results.map do |cask|
        if cask.installed?
          pretty_installed(cask.token)
        else
          cask.token
        end
      end
    end
  end
end
