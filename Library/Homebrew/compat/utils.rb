module Tty
  module_function

  def white
    odeprecated "Tty.white", "Tty.reset.bold"
    reset.bold
  end
end

def puts_columns(items)
  odeprecated "puts_columns", "puts Formatter.columns"
  puts Formatter.columns(items)
end

def plural(n, s = "s")
  odeprecated "#plural", "Formatter.pluralize"
  (n == 1) ? "" : s
end
