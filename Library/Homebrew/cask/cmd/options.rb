module Cask
  class Cmd
    module Options
      def self.included(klass)
        klass.extend(ClassMethods)
      end

      module ClassMethods
        def options
          @options ||= {}
          return @options unless superclass.respond_to?(:options)

          superclass.options.merge(@options)
        end

        def option(name, method, default_value = nil)
          @options ||= {}
          @options[name] = method

          return if method.respond_to?(:call)

          define_method(:"#{method}=") do |value|
            instance_variable_set(:"@#{method}", value)
          end

          if [true, false].include?(default_value)
            define_method(:"#{method}?") do
              return default_value unless instance_variable_defined?(:"@#{method}")

              instance_variable_get(:"@#{method}") == true
            end
          else
            define_method(:"#{method}") do
              return default_value unless instance_variable_defined?(:"@#{method}")

              instance_variable_get(:"@#{method}")
            end
          end
        end
      end

      def process_arguments(*arguments)
        parser = OptionParser.new do |opts|
          next if self.class.options.nil?

          self.class.options.each do |option_name, option_method|
            option_type = case option_name.split(/(\ |\=)/).last
            when "PATH"
              Pathname
            when /\w+(,\w+)+/
              Array
            end

            opts.on(option_name, *option_type) do |value|
              if option_method.respond_to?(:call)
                option_method.call(value)
              else
                send(:"#{option_method}=", value)
              end
            end
          end
        end
        parser.parse(*arguments)
      end
    end
  end
end
