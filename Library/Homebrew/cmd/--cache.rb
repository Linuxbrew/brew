#:  * `--cache`:
#:    Display Homebrew's download cache. See also `HOMEBREW_CACHE`.
#:
#:  * `--cache` <formula>:
#:    Display the file or directory used to cache <formula>.

require "cmd/fetch"

module Homebrew
  module_function

  def __cache
    if ARGV.named.empty?
      puts HOMEBREW_CACHE
    else
      ARGV.formulae.each do |f|
        if fetch_bottle?(f)
          puts f.bottle.cached_download
        else
          puts f.cached_download
        end
      end
    end
  end
end
