#:  * `ruby` [<ruby options>]:
#:    Run a Ruby instance with Homebrew's libraries loaded.
#:    For example:
#       brew ruby -e "puts :gcc.f.deps"
#       brew ruby script.rb

module Homebrew
  module_function

  def ruby
    exec ENV["HOMEBREW_RUBY_PATH"], "-I", $LOAD_PATH.join(File::PATH_SEPARATOR), "-rglobal", "-rdev-cmd/irb", *ARGV
  end
end
