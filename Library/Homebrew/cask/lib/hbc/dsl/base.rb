module Hbc
  class DSL
    class Base
      extend Forwardable

      def initialize(cask, command = SystemCommand)
        @cask = cask
        @command = command
      end

      def_delegators :@cask, :token, :version, :caskroom_path, :staged_path, :appdir, :language

      def system_command(executable, options = {})
        @command.run!(executable, options)
      end

      def method_missing(method, *)
        if method
          underscored_class = self.class.name.gsub(/([[:lower:]])([[:upper:]][[:lower:]])/, '\1_\2').downcase
          section = underscored_class.downcase.split("::").last
          Utils.method_missing_message(method, @cask.to_s, section)
          nil
        else
          super
        end
      end

      def respond_to_missing?(*)
        true
      end
    end
  end
end
