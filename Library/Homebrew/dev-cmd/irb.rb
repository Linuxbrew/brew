#:  * `irb` [`--examples`] [`--pry`]:
#:    Enter the interactive Homebrew Ruby shell.
#:
#:    If `--examples` is passed, several examples will be shown.
#:    If `--pry` is passed or HOMEBREW_PRY is set, pry will be
#:    used instead of irb.

require "cli_parser"

class Symbol
  def f(*args)
    Formulary.factory(to_s, *args)
  end
end

class String
  def f(*args)
    Formulary.factory(self, *args)
  end
end

module Homebrew
  module_function

  def irb
    Homebrew::CLI::Parser.parse do
      switch "--examples"
      switch "--pry", env: :pry
    end

    if args.examples?
      puts "'v8'.f # => instance of the v8 formula"
      puts ":hub.f.installed?"
      puts ":lua.f.methods - 1.methods"
      puts ":mpd.f.recursive_dependencies.reject(&:installed?)"
      return
    end

    if args.pry?
      Homebrew.install_gem_setup_path! "pry"
      require "pry"
      Pry.config.prompt_name = "brew"
    else
      require "irb"
    end

    require "formula"
    require "keg"
    require "cask/all"

    ohai "Interactive Homebrew Shell"
    puts "Example commands available with: brew irb --examples"
    if args.pry?
      Pry.start
    else
      IRB.start
    end
  end
end
