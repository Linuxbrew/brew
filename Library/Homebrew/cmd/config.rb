#:  * `config`:
#:    Show Homebrew and system configuration useful for debugging. If you file
#:    a bug report, you will likely be asked for this information if you do not
#:    provide it.

require "system_config"

module Homebrew
  module_function

  def config
    SystemConfig.dump_verbose_config
  end
end
