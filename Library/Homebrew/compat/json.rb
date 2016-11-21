require "json"

module Utils
  module JSON
    module_function

    Error = Class.new(StandardError)

    def load(str)
      odeprecated "Utils::JSON.load", "JSON.parse"
      ::JSON.parse(str)
    rescue ::JSON::ParserError => e
      raise Error, e.message
    end

    def dump(obj)
      odeprecated "Utils::JSON.dump", "JSON.generate"
      ::JSON.generate(obj)
    end

    def stringify_keys(obj)
      odeprecated "Utils::JSON.stringify_keys"
      case obj
      when Array
        obj.map { |val| stringify_keys(val) }
      when Hash
        obj.inject({}) do |result, (key, val)|
          key = key.respond_to?(:to_s) ? key.to_s : key
          val = stringify_keys(val)
          result.merge!(key => val)
        end
      else
        obj
      end
    end
  end
end
