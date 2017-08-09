# Taken from https://github.com/marcandre/backports/blob/v3.8.0/lib/backports/2.4.0/string/match.rb
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
