require "optparse"
require "ostruct"

module Homebrew
  module CLI
    class Parser
      def self.parse(&block)
        new(&block).parse
      end

      def initialize(&block)
        @parser = OptionParser.new
        @parsed_args = OpenStruct.new
        # undefine tap to allow --tap argument
        @parsed_args.instance_eval { undef tap }
        instance_eval(&block)
      end

      def switch(*names, description: nil, env: nil)
        description = option_to_description(*names) if description.nil?
        global_switch = names.first.is_a?(Symbol)
        names, env = common_switch(*names) if global_switch
        @parser.on(*names, description) do
          enable_switch(*names, global_switch)
        end
        enable_switch(*names, global_switch) if !env.nil? &&
                                                !ENV["HOMEBREW_#{env.to_s.upcase}"].nil?
      end

      def comma_array(name, description: nil)
        description = option_to_description(name) if description.nil?
        @parser.on(name, OptionParser::REQUIRED_ARGUMENT, Array, description) do |list|
          @parsed_args[option_to_name(name)] = list
        end
      end

      def flag(name, description: nil)
        if name.end_with? "="
          required = OptionParser::REQUIRED_ARGUMENT
          name.chomp! "="
        else
          required = OptionParser::OPTIONAL_ARGUMENT
        end
        description = option_to_description(name) if description.nil?
        @parser.on(name, description, required) do |option_value|
          @parsed_args[option_to_name(name)] = option_value
        end
      end

      def option_to_name(name)
        name.sub(/\A--?/, "").tr("-", "_")
      end

      def option_to_description(*names)
        names.map { |name| name.to_s.sub(/\A--?/, "").tr("-", " ") }.sort.last
      end

      def parse(cmdline_args = ARGV)
        @parser.parse(cmdline_args)
        @parsed_args
      end

      private

      def enable_switch(*names, global_switch)
        names.each do |name|
          if global_switch
            Homebrew.args["#{option_to_name(name)}?"] = true
            next
          end
          @parsed_args["#{option_to_name(name)}?"] = true
        end
      end

      # These are common/global switches accessible throughout Homebrew
      def common_switch(name)
        case name
        when :quiet   then [["-q", "--quiet"], :quiet]
        when :verbose then [["-v", "--verbose"], :verbose]
        when :debug   then [["-d", "--debug"], :debug]
        when :force   then [["-f", "--force"], :force]
        else name
        end
      end
    end
  end
end
