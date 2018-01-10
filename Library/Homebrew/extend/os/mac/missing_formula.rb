module Homebrew
  module MissingFormula
    class << self
      def blacklisted_reason(name)
        case name.downcase
        when "xcode"
          if MacOS.version >= :lion
            <<~EOS
              Xcode can be installed from the App Store.
            EOS
          else
            <<~EOS
              Xcode can be installed from #{Formatter.url("https://developer.apple.com/download/more/")}.
            EOS
          end
        else
          generic_blacklisted_reason(name)
        end
      end
    end
  end
end
