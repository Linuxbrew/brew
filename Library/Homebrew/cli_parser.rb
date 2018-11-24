require "optparse"
require "ostruct"
require "set"

module Homebrew
  module CLI
    class Parser
      attr_reader :processed_options

      def self.parse(args = ARGV, &block)
        new(&block).parse(args)
      end

      def self.global_options
        {
          quiet:   [["-q", "--quiet"], :quiet, "Suppress any warnings."],
          verbose: [["-v", "--verbose"], :verbose, "Make some output more verbose."],
          debug:   [["-d", "--debug"], :debug, "Display any debugging information."],
          force:   [["-f", "--force"], :force, "Override warnings and enable potentially unsafe operations."],
        }
      end

      def initialize(&block)
        @parser = OptionParser.new
        Homebrew.args = OpenStruct.new
        # undefine tap to allow --tap argument
        Homebrew.args.instance_eval { undef tap }
        @constraints = []
        @conflicts = []
        @processed_options = []
        @desc_line_length = 43
        instance_eval(&block)
        post_initialize
      end

      def post_initialize
        @parser.on_tail("-h", "--help", "Show this message.") do
          puts generate_help_text
          exit 0
        end
      end

      def switch(*names, description: nil, env: nil, required_for: nil, depends_on: nil)
        global_switch = names.first.is_a?(Symbol)
        names, env, default_description = common_switch(*names) if global_switch
        if description.nil? && global_switch
          description = default_description
        elsif description.nil?
          description = option_to_description(*names)
        end
        process_option(*names, description)
        @parser.on(*names, *wrap_option_desc(description)) do
          enable_switch(*names)
        end

        names.each do |name|
          set_constraints(name, required_for: required_for, depends_on: depends_on)
        end

        enable_switch(*names) if !env.nil? && !ENV["HOMEBREW_#{env.to_s.upcase}"].nil?
      end

      def usage_banner(text)
        @parser.banner = "#{text}\n"
      end

      def usage_banner_text
        @parser.banner
      end

      def comma_array(name, description: nil)
        description = option_to_description(name) if description.nil?
        process_option(name, description)
        @parser.on(name, OptionParser::REQUIRED_ARGUMENT, Array, *wrap_option_desc(description)) do |list|
          Homebrew.args[option_to_name(name)] = list
        end
      end

      def flag(*names, description: nil, required_for: nil, depends_on: nil)
        if names.any? { |name| name.end_with? "=" }
          required = OptionParser::REQUIRED_ARGUMENT
        else
          required = OptionParser::OPTIONAL_ARGUMENT
        end
        names.map! { |name| name.chomp "=" }
        description = option_to_description(*names) if description.nil?
        process_option(*names, description)
        @parser.on(*names, *wrap_option_desc(description), required) do |option_value|
          names.each do |name|
            Homebrew.args[option_to_name(name)] = option_value
          end
        end

        names.each do |name|
          set_constraints(name, required_for: required_for, depends_on: depends_on)
        end
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
          "--#{name.tr("_", "-")}"
        end
      end

      def option_to_description(*names)
        names.map { |name| name.to_s.sub(/\A--?/, "").tr("-", " ") }.max
      end

      def summary
        @parser.to_s
      end

      def parse(cmdline_args = ARGV)
        remaining_args = @parser.parse(cmdline_args)
        check_constraint_violations
        Homebrew.args[:remaining] = remaining_args
        Homebrew.args.freeze
        @parser
      end

      def global_option?(name)
        Homebrew::CLI::Parser.global_options.key?(name.to_sym)
      end

      def generate_help_text
        @parser.to_s.sub(/^/, "#{Tty.bold}Usage: brew#{Tty.reset} ")
               .gsub(/`(.*?)`/m, "#{Tty.bold}\\1#{Tty.reset}")
               .gsub(%r{<([^\s]+?://[^\s]+?)>}) { |url| Formatter.url(url) }
               .gsub(/<(.*?)>/m, "#{Tty.underline}\\1#{Tty.reset}")
               .gsub(/\*(.*?)\*/m, "#{Tty.underline}\\1#{Tty.reset}")
      end

      private

      def enable_switch(*names)
        names.each do |name|
          Homebrew.args["#{option_to_name(name)}?"] = true
        end
      end

      # These are common/global switches accessible throughout Homebrew
      def common_switch(name)
        Homebrew::CLI::Parser.global_options.fetch(name, name)
      end

      def option_passed?(name)
        Homebrew.args.respond_to?(name) || Homebrew.args.respond_to?("#{name}?")
      end

      def wrap_option_desc(desc)
        Formatter.wrap(desc, @desc_line_length).split("\n")
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

      def process_option(*args)
        option, = @parser.make_switch(args)
        @processed_options << [option.short.first, option.long.first, option.arg, option.desc.first]
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
