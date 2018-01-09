module Tty
  module_function

  def white
    odisabled "Tty.white", "Tty.reset.bold"
  end
end

def puts_columns(_)
  odisabled "puts_columns", "puts Formatter.columns"
end

def plural(_, _)
  odisabled "#plural", "Formatter.pluralize"
end
