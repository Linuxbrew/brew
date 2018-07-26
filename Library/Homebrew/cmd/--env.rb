#:  * `--env` [`--shell=`(<shell>|`auto`)|`--plain`]:
#:    Show a summary of the Homebrew build environment as a plain list.
#:
#:    Pass `--shell=`<shell> to generate a list of environment variables for the
#:    specified shell, or `--shell=auto` to detect the current shell.
#:
#:    If the command's output is sent through a pipe and no shell is specified,
#:    the list is formatted for export to `bash`(1) unless `--plain` is passed.

require "extend/ENV"
require "build_environment"
require "utils/shell"

module Homebrew
  module_function

  def __env
    ENV.activate_extensions!
    ENV.deps = ARGV.formulae if superenv?
    ENV.setup_build_environment
    ENV.universal_binary if ARGV.build_universal?

    shell_value = ARGV.value("shell")

    if ARGV.include?("--plain")
      shell = nil
    elsif shell_value.nil?
      # legacy behavior
      shell = :bash unless $stdout.tty?
    elsif shell_value == "auto"
      shell = Utils::Shell.parent || Utils::Shell.preferred
    elsif shell_value
      shell = Utils::Shell.from_path(shell_value)
    end

    env_keys = build_env_keys(ENV)
    if shell.nil?
      dump_build_env ENV
    else
      env_keys.each do |key|
        puts Utils::Shell.export_value(key, ENV[key], shell)
      end
    end
  end
end
