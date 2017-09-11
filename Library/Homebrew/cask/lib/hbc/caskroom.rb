module Hbc
  module Caskroom
    module_function

    def ensure_caskroom_exists
      return if Hbc.caskroom.exist?

      ohai "Creating Caskroom at #{Hbc.caskroom}" if $stdout.tty?
      sudo = !Hbc.caskroom.parent.writable?

      ohai "We'll set permissions properly so we won't need sudo in the future" if $stdout.tty? && sudo

      SystemCommand.run("/bin/mkdir", args: ["-p", Hbc.caskroom], sudo: sudo)
      SystemCommand.run("/bin/chmod", args: ["g+rwx", Hbc.caskroom], sudo: sudo)
      SystemCommand.run("/usr/sbin/chown", args: [Utils.current_user, Hbc.caskroom], sudo: sudo)
      SystemCommand.run("/usr/bin/chgrp", args: ["admin", Hbc.caskroom], sudo: sudo)
    end
  end
end
