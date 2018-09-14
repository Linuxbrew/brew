unless String.method_defined? :match?
  class String
    def match?(*args)
      # Fiber to avoid setting $~
      f = Fiber.new do
        !match(*args).nil?
      end
      f.resume
    end
  end
end
