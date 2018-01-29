module Homebrew
  module_function

  def method_missing(method, *args, &block)
    if instance_methods.include?(method)
      odisabled "#{self}##{method}", "'module_function' or 'def self.#{method}' to convert it to a class method"
    end
    super
  end

  def respond_to_missing?(method, include_private = false)
    return true if method_defined?(method)
    super(method, include_private)
  end
end
