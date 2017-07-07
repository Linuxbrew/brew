require "delegate"

module Test
  module Helper
    module OutputAsTTY
      module TTYTrue
        def tty?
          true
        end

        alias isatty tty?
      end

      # This is a custom wrapper for the `output` matcher,
      # used for testing output to a TTY:
      #
      #   expect {
      #     print "test" if $stdout.tty?
      #   }.to output("test").to_stdout.as_tty
      #
      #   expect {
      #     # command
      #   }.to output(...).to_stderr.as_tty.with_color
      #
      class Output < SimpleDelegator
        def matches?(block)
          return super(block) unless @tty

          colored_tty_block = if @output == :stdout
            lambda do
              $stdout.extend(TTYTrue)
              block.call
            end
          elsif @output == :stderr
            lambda do
              $stderr.extend(TTYTrue)
              block.call
            end
          else
            raise "`as_tty` can only be chained to `stdout` or `stderr`."
          end

          return super(colored_tty_block) if @colors

          uncolored_tty_block = lambda do
            begin
              out_stream = StringIO.new
              err_stream = StringIO.new

              old_stdout = $stdout
              old_stderr = $stderr

              $stdout = out_stream
              $stderr = err_stream

              colored_tty_block.call
            ensure
              $stdout = old_stdout
              $stderr = old_stderr

              $stdout.print Tty.strip_ansi(out_stream.string)
              $stderr.print Tty.strip_ansi(err_stream.string)
            end
          end

          super(uncolored_tty_block)
        end

        def to_stdout
          @output = :stdout
          super
          self
        end

        def to_stderr
          @output = :stderr
          super
          self
        end

        def as_tty
          @tty = true
          self
        end

        def with_color
          @colors = true
          return self if @tty
          raise "`with_color` can only be chained to `as_tty`."
        end
      end

      def output(*args)
        core_matcher = super(*args)
        Output.new(core_matcher)
      end
    end
  end
end
