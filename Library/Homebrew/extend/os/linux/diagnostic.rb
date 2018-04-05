require "tempfile"

module Homebrew
  module Diagnostic
    class Checks
      alias generic_check_tmpdir_sticky_bit check_tmpdir_sticky_bit

      def check_tmpdir_sticky_bit
        message = generic_check_tmpdir_sticky_bit
        return if message.nil?
        message + <<~EOS
          If you don't have administrative privileges on this machine,
          create a directory and set the HOMEBREW_TEMP environment variable,
          for example:
            export HOMEBREW_TEMP=~/tmp
            mkdir -p "$HOMEBREW_TEMP"
            chmod 1755 "$HOMEBREW_TEMP"
            echo "export HOMEBREW_TEMP=\"$HOMEBREW_TEMP\"" >> #{shell_profile}
        EOS
      end

      def check_ld_vars
        ld_vars = ENV.keys.grep(/^LD_/)
        return if ld_vars.empty?

        values = ld_vars.map { |var| "#{var}: #{ENV.fetch(var)}" }
        message = inject_file_list values, <<~EOS
          Setting LD_* vars can break dynamic linking.
          Set variables:
        EOS

        message
      end

      def check_xdg_data_dirs
        return if ENV["XDG_DATA_DIRS"].nil? || ENV["XDG_DATA_DIRS"].empty?
        return if ENV["XDG_DATA_DIRS"].split(File::PATH_SEPARATOR).include?(HOMEBREW_PREFIX/"share")
        <<~EOS.undent
          Homebrew's share was not found in your XDG_DATA_DIRS but you have
          this variable set to include other locations.
          Some programs like `vapigen` may not work correctly.
          Consider adding Homebrew's share directory to XDG_DATA_DIRS like so
              echo 'export XDG_DATA_DIRS="#{HOMEBREW_PREFIX}/share:$XDG_DATA_DIRS"' >> #{shell_profile}
        EOS
      end

      def check_tmpdir_executable
        f = Tempfile.new(%w[homebrew_check_tmpdir_executable .sh], HOMEBREW_TEMP)
        f.write "#!/bin/sh\n"
        f.chmod 0700
        f.close
        return if system f.path
        <<~EOS.undent
          The directory #{HOMEBREW_TEMP} does not permit executing
          programs. It is likely mounted as "noexec". Please set HOMEBREW_TEMP
          in your #{shell_profile} to a different directory, for example:
            export HOMEBREW_TEMP=~/tmp
            echo 'export HOMEBREW_TEMP=~/tmp' >> #{shell_profile}
        EOS
      ensure
        f.unlink
      end
    end
  end
end
