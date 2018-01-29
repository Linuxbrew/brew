require "json"

module Utils
  module JSON
    module_function

    def load(_)
      odisabled "Utils::JSON.load", "JSON.parse"
    end

    def dump(_)
      odisabled "Utils::JSON.dump", "JSON.generate"
    end

    def stringify_keys(_)
      odisabled "Utils::JSON.stringify_keys"
    end
  end
end
