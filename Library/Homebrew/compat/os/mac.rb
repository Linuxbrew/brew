module OS
  module Mac
    class << self
      def release
        odeprecated "MacOS.release", "MacOS.version"
        version
      end
    end
  end
end
