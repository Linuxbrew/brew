module HashValidator
  refine Hash do
    def assert_valid_keys!(*valid_keys)
      unknown_keys = keys - valid_keys
      return if unknown_keys.empty?

      raise ArgumentError, "invalid keys: #{unknown_keys.map(&:inspect).join(", ")}"
    end
  end
end
