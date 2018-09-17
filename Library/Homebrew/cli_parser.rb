require "optparse"
require "ostruct"
require "set"

module Homebrew
  module CLI
    class Parser
      def self.parse(args = ARGV, &block)
        new(&block).parse(args)
      end

      def initialize(&block)
        @parser = OptionParser.new
        Homebrew.args = OpenStruct.new
        # undefine tap to allow --tap argument
        Homebrew.args.instance_eval { undef tap }
        @constraints = []
        @conflicts = []
        instance_eval(&block)
      end

      def switch(*names, description: nil, env: nil, required_for: nil, depends_on: nil)
        description = option_to_description(*names) if description.nil?
        global_switch = names.first.is_a?(Symbol)
        names, env = common_switch(*names) if global_switch
        @parser.on(*names, description) do
          enable_switch(*names)
        end

        names.each do |name|
          set_constraints(name, required_for: required_for, depends_on: depends_on)
        end

        enable_switch(*names) if !env.nil? && !ENV["HOMEBREW_#{env.to_s.upcase}"].nil?
      end

      def comma_array(name, description: nil)
        description = option_to_description(name) if description.nil?
        @parser.on(name, OptionParser::REQUIRED_ARGUMENT, Array, description) do |list|
          Homebrew.args[option_to_name(name)] = list
        end
      end

      def flag(name, description: nil, required_for: nil, depends_on: nil)
        if name.end_with? "="
          required = OptionParser::REQUIRED_ARGUMENT
          name.chomp! "="
        else
          required = OptionParser::OPTIONAL_ARGUMENT
        end
        description = option_to_description(name) if description.nil?
        @parser.on(name, description, required) do |option_value|
          Homebrew.args[option_to_name(name)] = option_value
        end

        set_constraints(name, required_for: required_for, depends_on: depends_on)
      end

      def conflicts(*options)
        @conflicts << options.map { |option| option_to_name(option) }
      end

      def option_to_name(option)
        option.sub(/\A--?/, "")
              .tr("-", "_")
              .delete("=")
      end

      def name_to_option(name)
        if name.length == 1
          "-#{name}"
        else
          "--#{name}"
        end
      end

      def option_to_description(*names)
        names.map { |name| name.to_s.sub(/\A--?/, "").tr("-", " ") }.max
      end

      def parse(cmdline_args)
        remaining_args = @parser.parse(cmdline_args)
        check_constraint_violations
        Homebrew.args[:remaining] = remaining_args
      end

      private

      def enable_switch(*names)
        names.each do |name|
          Homebrew.args["#{option_to_name(name)}?"] = true
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
        Homebrew.args.respond_to?(name) || Homebrew.args.respond_to?("#{name}?")
      end

      def set_constraints(name, depends_on:, required_for:)
        secondary = option_to_name(name)
        unless required_for.nil?
          primary = option_to_name(required_for)
          @constraints << [primary, secondary, :mandatory]
        end

        return if depends_on.nil?

        primary = option_to_name(depends_on)
        @constraints << [primary, secondary, :optional]
      end

      def check_constraints
        @constraints.each do |primary, secondary, constraint_type|
          primary_passed = option_passed?(primary)
          secondary_passed = option_passed?(secondary)
          if :mandatory.equal?(constraint_type) && primary_passed && !secondary_passed
            raise OptionConstraintError.new(primary, secondary)
          end
          if secondary_passed && !primary_passed
            raise OptionConstraintError.new(primary, secondary, missing: true)
          end
        end
      end

      def check_conflicts
        @conflicts.each do |mutually_exclusive_options_group|
          violations = mutually_exclusive_options_group.select do |option|
            option_passed? option
          end

          next if violations.count < 2

          raise OptionConflictError, violations.map(&method(:name_to_option))
        end
      end

      def check_invalid_constraints
        @conflicts.each do |mutually_exclusive_options_group|
          @constraints.each do |p, s|
            next unless Set[p, s].subset?(Set[*mutually_exclusive_options_group])

            raise InvalidConstraintError.new(p, s)
          end
        end
      end

      def check_constraint_violations
        check_invalid_constraints
        check_conflicts
        check_constraints
      end
    end

    class OptionConstraintError < RuntimeError
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
      def initialize(args)
        args_list = args.map(&Formatter.public_method(:option))
                        .join(" and ")
        super <<~EOS
          Options #{args_list} are mutually exclusive.
        EOS
      end
    end

    class InvalidConstraintError < RuntimeError
      def initialize(arg1, arg2)
        super <<~EOS
          `#{arg1}` and `#{arg2}` cannot be mutually exclusive and mutually dependent simultaneously
        EOS
      end
    end
  end
end
