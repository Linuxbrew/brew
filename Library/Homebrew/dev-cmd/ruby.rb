#:  * `ruby` [<ruby options>]:
#:    Run a Ruby instance with Homebrew's libraries loaded.
#:
#:    *Example:* `brew ruby -e "puts :gcc.f.deps"` or `brew ruby script.rb`

require "cli_parser"

module Homebrew
  module_function

  def ruby_args
    Homebrew::CLI::Parser.new do
      usage_banner <<~EOS
        `ruby` [<ruby options>]

        Run a Ruby instance with Homebrew's libraries loaded.

        *Example:* `brew ruby -e "puts :gcc.f.deps"` or `brew ruby script.rb`
      EOS
      switch "-e",
        description: "Execute the provided string argument as a script."
      switch :verbose
      switch :debug
    end
  end

  def ruby
    ruby_args.parse

    exec ENV["HOMEBREW_RUBY_PATH"], "-I", $LOAD_PATH.join(File::PATH_SEPARATOR), "-rglobal", "-rdev-cmd/irb", *ARGV
  end
end
