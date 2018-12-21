module I18n
  module HashRefinements
    refine Hash do
      def slice(*keep_keys)
        h = {}
        keep_keys.each { |key| h[key] = fetch(key) if has_key?(key) }
        h
      end

      def except(*less_keys)
        slice(*keys - less_keys)
      end

      def deep_symbolize_keys
        each_with_object({}) do |(key, value), result|
          value = value.deep_symbolize_keys if value.is_a?(Hash)
          result[symbolize_key(key)] = value
          result
        end
      end

      # deep_merge_hash! by Stefan Rusterholz, see http://www.ruby-forum.com/topic/142809
      def deep_merge!(data)
        merger = lambda do |_key, v1, v2|
          Hash === v1 && Hash === v2 ? v1.merge(v2, &merger) : v2
        end
        merge!(data, &merger)
      end

      private

      def symbolize_key(key)
        key.respond_to?(:to_sym) ? key.to_sym : key
      end
    end
  end
end
