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
        @depends = []
        @conflicts = []
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

      def depends(primary, secondary, mandatory: false)
        @depends << [primary, secondary, mandatory]
      end

      def conflicts(primary, secondary)
        @conflicts << [primary, secondary]
      end

      def option_to_name(name)
        name.sub(/\A--?/, "").tr("-", "_")
      end

      def option_to_description(*names)
        names.map { |name| name.to_s.sub(/\A--?/, "").tr("-", " ") }.sort.last
      end

      def parse(cmdline_args = ARGV)
        @parser.parse(cmdline_args)
        check_constraint_violations
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

      def option_passed?(name)
        @parsed_args.respond_to?(name) || @parsed_args.respond_to?("#{name}?")
      end

      def check_depends
        @depends.each do |primary, secondary, required|
          primary_passed = option_passed?(primary)
          secondary_passed = option_passed?(secondary)
          raise OptionDependencyError.new(primary, secondary) if required && primary_passed &&
                                                                 !secondary_passed
          raise OptionDependencyError.new(primary, secondary, missing: true) if secondary_passed &&
                                                                                !primary_passed
        end
      end

      def check_conflicts
        @conflicts.each do |primary, secondary|
          primary_passed = option_passed?(primary)
          secondary_passed = option_passed?(secondary)
          raise OptionConflictError.new(primary, secondary) if primary_passed && secondary_passed
        end
      end

      def check_constraint_violations
        check_conflicts
        check_depends
      end
    end

    class OptionDependencyError < RuntimeError
      def initialize(arg1, arg2, missing: false)
        if !missing
          message = <<~EOS
            `#{arg1}` and `#{arg2}` should be passed together
          EOS
        else
          message = <<~EOS
            `#{arg2}` cannot be passed without `#{arg1}`
          EOS
        end
        super message
      end
    end

    class OptionConflictError < RuntimeError
      def initialize(arg1, arg2)
        super <<~EOS
          `#{arg1}` and `#{arg2}` should not be passed together
        EOS
      end
    end
  end
end
