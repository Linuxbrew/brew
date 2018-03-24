module Utils
  module EnvVars
    class << self
      def pry?
        !ENV["HOMEBREW_PRY"].nil?
      end
    end
  end
end
