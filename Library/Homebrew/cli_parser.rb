require "optparse"
require "ostruct"

module Homebrew
  module CLI
    class Parser
      def initialize(&block)
        @parser = OptionParser.new
        @parsed_args = OpenStruct.new
        instance_eval(&block)
      end

      def switch(*names, description: nil, env: nil)
        description = option_to_description(*names) if description.nil?
        @parser.on(*names, description) do
          enable_switch(*names)
        end
        enable_switch(*names) if !env.nil? && !ENV["HOMEBREW_#{env.to_s.upcase}"].nil?
      end

      def comma_array(name, description: nil)
        description = option_to_description(name) if description.nil?
        @parser.on(name, OptionParser::REQUIRED_ARGUMENT, Array, description) do |list|
          @parsed_args[option_to_name(name)] = list
        end
      end

      def flag(name, description: nil, required: false)
        if required
          option_required = OptionParser::REQUIRED_ARGUMENT
        else
          option_required = OptionParser::OPTIONAL_ARGUMENT
        end
        description = option_to_description(name) if description.nil?
        @parser.on(name, description, option_required) do |option_value|
          @parsed_args[option_to_name(name)] = option_value
        end
      end

      def option_to_name(name)
        name.sub(/\A--?/, "").tr("-", "_")
      end

      def option_to_description(*names)
        names.map { |name| name.sub(/\A--?/, "").tr("-", " ") }.sort.last
      end

      def parse(cmdline_args = ARGV)
        @parser.parse!(cmdline_args)
        @parsed_args
      end

      private

      def enable_switch(*names)
        names.each do |name|
          @parsed_args["#{option_to_name(name)}?"] = true
        end
      end
    end
  end
end
