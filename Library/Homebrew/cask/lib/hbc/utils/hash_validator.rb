module HashValidator
  def assert_valid_keys(*valid_keys)
    unknown_keys = keys - valid_keys
    return if unknown_keys.empty?
    raise %Q(Unknown keys: #{unknown_keys.inspect}. Running "brew update" will likely fix it.)
  end
end
