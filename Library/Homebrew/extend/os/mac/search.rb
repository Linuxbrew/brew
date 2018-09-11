require "cask/cask"
require "cask/cask_loader"

module Homebrew
  module Search
    module Extension
      def search_descriptions(string_or_regex)
        super

        puts

        ohai "Casks"
        Cask::Cask.to_a.extend(Searchable)
                  .search(string_or_regex, &:name)
                  .each do |cask|
          puts "#{Tty.bold}#{cask.token}:#{Tty.reset} #{cask.name.join(", ")}"
        end
      end

      def search_casks(string_or_regex)
        if string_or_regex.is_a?(String) && string_or_regex.match?(HOMEBREW_TAP_CASK_REGEX)
          return begin
            [Cask::CaskLoader.load(string_or_regex).token]
          rescue Cask::CaskUnavailableError
            []
          end
        end

        results = Cask::Cask.search(string_or_regex, &:token).sort_by(&:token)

        results.map do |cask|
          if cask.installed?
            pretty_installed(cask.token)
          else
            cask.token
          end
        end
      end
    end

    prepend Extension
  end
end
