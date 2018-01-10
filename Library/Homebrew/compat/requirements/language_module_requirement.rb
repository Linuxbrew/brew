require "requirement"

class LanguageModuleRequirement < Requirement
  fatal true

  def initialize(language, module_name, import_name = nil)
    @language = language
    @module_name = module_name
    @import_name = import_name || module_name
    super([language, module_name, import_name])
  end

  satisfy(build_env: false) { quiet_system(*the_test) }

  def message
    s = <<~EOS
      Unsatisfied dependency: #{@module_name}
      Homebrew does not provide special #{@language.to_s.capitalize} dependencies; install with:
        `#{command_line} #{@module_name}`
    EOS

    unless [:python, :perl, :ruby].include? @language
      s += <<~EOS
        You may need to: `brew install #{@language}`

      EOS
    end

    s
  end

  def the_test
    case @language
    when :lua
      ["/usr/bin/env", "luarocks-5.2", "show", @import_name.to_s]
    when :lua51
      ["/usr/bin/env", "luarocks-5.1", "show", @import_name.to_s]
    when :perl
      ["/usr/bin/env", "perl", "-e", "use #{@import_name}"]
    when :python
      ["/usr/bin/env", "python", "-c", "import #{@import_name}"]
    when :python3
      ["/usr/bin/env", "python3", "-c", "import #{@import_name}"]
    when :ruby
      ["/usr/bin/env", "ruby", "-rubygems", "-e", "require '#{@import_name}'"]
    end
  end

  def command_line
    case @language
    when :lua     then "luarocks-5.2 install"
    when :lua51   then "luarocks-5.1 install"
    when :perl    then "cpan -i"
    when :python  then "pip install"
    when :python3 then "pip3 install"
    when :ruby    then "gem install"
    end
  end

  def display_s
    "#{@module_name} (#{@language} module)"
  end
end
