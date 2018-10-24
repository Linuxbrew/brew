module Utils
  class Bottles
    class Collector
      module Compat
        private

        def tag_without_or_later(tag)
          return super unless tag.to_s.end_with?("_or_later")

          odeprecated "`or_later` bottles",
                      "bottles without `or_later` (or_later is implied now)"
          tag.to_s[/(\w+)_or_later$/, 1].to_sym
        end
      end

      prepend Compat
    end
  end
end
