require "shellwords"

module SystemCommandCompatibilityLayer
  def initialize(executable, args: [], **options)
    if args.empty? && !File.exist?(executable)
      odeprecated "`system_command` with a shell string", "`system_command` with the `args` parameter"
      executable, *args = Shellwords.shellsplit(executable)
    end

    super(executable, args: args, **options)
  end
end

module Hbc
  class SystemCommand
    prepend SystemCommandCompatibilityLayer
  end
end
