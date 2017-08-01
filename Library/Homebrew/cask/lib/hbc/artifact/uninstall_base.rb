require "pathname"
require "timeout"

require "hbc/artifact/base"

module Hbc
  module Artifact
    class UninstallBase < Base
      ORDERED_DIRECTIVES = [
        :early_script,
        :launchctl,
        :quit,
        :signal,
        :login_item,
        :kext,
        :script,
        :pkgutil,
        :delete,
        :trash,
        :rmdir,
      ].freeze

      def dispatch_uninstall_directives
        directives_set = @cask.artifacts[stanza]
        ohai "Running #{stanza} process for #{@cask}; your password may be necessary"

        directives_set.each do |directives|
          warn_for_unknown_directives(directives)
        end

        ORDERED_DIRECTIVES.each do |directive_sym|
          directives_set.select { |h| h.key?(directive_sym) }.each do |directives|
            args = directives[directive_sym]
            send("uninstall_#{directive_sym}", *(args.is_a?(Hash) ? [args] : args))
          end
        end
      end

      private

      def stanza
        self.class.artifact_dsl_key
      end

      def warn_for_unknown_directives(directives)
        unknown_keys = directives.keys - ORDERED_DIRECTIVES
        return if unknown_keys.empty?
        opoo %Q(Unknown arguments to #{stanza} -- #{unknown_keys.inspect}. Running "brew update; brew cleanup; brew cask cleanup" will likely fix it.)
      end

      # Preserve prior functionality of script which runs first. Should rarely be needed.
      # :early_script should not delete files, better defer that to :script.
      # If Cask writers never need :early_script it may be removed in the future.
      def uninstall_early_script(directives)
        uninstall_script(directives, directive_name: :early_script)
      end

      # :launchctl must come before :quit/:signal for cases where app would instantly re-launch
      def uninstall_launchctl(*services)
        services.each do |service|
          ohai "Removing launchctl service #{service}"
          [false, true].each do |with_sudo|
            plist_status = @command.run("/bin/launchctl", args: ["list", service], sudo: with_sudo, print_stderr: false).stdout
            if plist_status =~ /^\{/
              @command.run!("/bin/launchctl", args: ["remove", service], sudo: with_sudo)
              sleep 1
            end
            paths = ["/Library/LaunchAgents/#{service}.plist",
                     "/Library/LaunchDaemons/#{service}.plist"]
            paths.each { |elt| elt.prepend(ENV["HOME"]) } unless with_sudo
            paths = paths.map { |elt| Pathname(elt) }.select(&:exist?)
            paths.each do |path|
              @command.run!("/bin/rm", args: ["-f", "--", path], sudo: with_sudo)
            end
            # undocumented and untested: pass a path to uninstall :launchctl
            next unless Pathname(service).exist?
            @command.run!("/bin/launchctl", args: ["unload", "-w", "--", service], sudo: with_sudo)
            @command.run!("/bin/rm",        args: ["-f", "--", service], sudo: with_sudo)
            sleep 1
          end
        end
      end

      def running_processes(bundle_id)
        @command.run!("/bin/launchctl", args: ["list"]).stdout.lines
                .map { |line| line.chomp.split("\t") }
                .map { |pid, state, id| [pid.to_i, state.to_i, id] }
                .select do |fields|
                  next if fields[0].zero?
                  fields[2] =~ /^#{Regexp.escape(bundle_id)}($|\.\d+)/
                end
      end

      # :quit/:signal must come before :kext so the kext will not be in use by a running process
      def uninstall_quit(*bundle_ids)
        bundle_ids.each do |bundle_id|
          ohai "Quitting application ID #{bundle_id}"
          next if running_processes(bundle_id).empty?
          @command.run!("/usr/bin/osascript", args: ["-e", %Q(tell application id "#{bundle_id}" to quit)], sudo: true)

          begin
            Timeout.timeout(3) do
              Kernel.loop do
                break if running_processes(bundle_id).empty?
              end
            end
          rescue Timeout::Error
            next
          end
        end
      end

      # :signal should come after :quit so it can be used as a backup when :quit fails
      def uninstall_signal(*signals)
        signals.flatten.each_slice(2) do |pair|
          unless pair.size == 2
            raise CaskInvalidError.new(@cask, "Each #{stanza} :signal must consist of 2 elements.")
          end

          signal, bundle_id = pair
          ohai "Signalling '#{signal}' to application ID '#{bundle_id}'"
          pids = running_processes(bundle_id).map(&:first)
          next unless pids.any?
          # Note that unlike :quit, signals are sent from the current user (not
          # upgraded to the superuser). This is a todo item for the future, but
          # there should be some additional thought/safety checks about that, as a
          # misapplied "kill" by root could bring down the system. The fact that we
          # learned the pid from AppleScript is already some degree of protection,
          # though indirect.
          odebug "Unix ids are #{pids.inspect} for processes with bundle identifier #{bundle_id}"
          Process.kill(signal, *pids)
          sleep 3
        end
      end

      def uninstall_login_item(*login_items)
        login_items.each do |name|
          ohai "Removing login item #{name}"
          @command.run!("/usr/bin/osascript",
                        args: ["-e", %Q(tell application "System Events" to delete every login item whose name is "#{name}")],
                        sudo: false)
          sleep 1
        end
      end

      # :kext should be unloaded before attempting to delete the relevant file
      def uninstall_kext(*kexts)
        kexts.each do |kext|
          ohai "Unloading kernel extension #{kext}"
          is_loaded = @command.run!("/usr/sbin/kextstat", args: ["-l", "-b", kext], sudo: true).stdout
          if is_loaded.length > 1
            @command.run!("/sbin/kextunload", args: ["-b", kext], sudo: true)
            sleep 1
          end
          @command.run!("/usr/sbin/kextfind", args: ["-b", kext], sudo: true).stdout.chomp.lines.each do |kext_path|
            ohai "Removing kernel extension #{kext_path}"
            @command.run!("/bin/rm", args: ["-rf", kext_path], sudo: true)
          end
        end
      end

      # :script must come before :pkgutil, :delete, or :trash so that the script file is not already deleted
      def uninstall_script(directives, directive_name: :script)
        executable, script_arguments = self.class.read_script_arguments(directives,
                                                                        "uninstall",
                                                                        { must_succeed: true, sudo: false },
                                                                        { print_stdout: true },
                                                                        directive_name)

        ohai "Running uninstall script #{executable}"
        raise CaskInvalidError.new(@cask, "#{stanza} :#{directive_name} without :executable.") if executable.nil?
        executable_path = @cask.staged_path.join(executable)

        unless executable_path.exist?
          message = "uninstall script #{executable} does not exist"
          raise CaskError, "#{message}." unless force?
          opoo "#{message}, skipping."
          return
        end

        @command.run("/bin/chmod", args: ["--", "+x", executable_path])
        @command.run(executable_path, script_arguments)
        sleep 1
      end

      def uninstall_pkgutil(*pkgs)
        ohai "Uninstalling packages:"
        pkgs.each do |regex|
          Hbc::Pkg.all_matching(regex, @command).each do |pkg|
            puts pkg.package_id
            pkg.uninstall
          end
        end
      end

      def each_resolved_path(action, paths)
        return enum_for(:each_resolved_path, action, paths) unless block_given?

        paths.each do |path|
          resolved_path = Pathname.new(path)

          resolved_path = resolved_path.expand_path if path.start_with?("~")

          if resolved_path.relative? || resolved_path.split.any? { |part| part.to_s == ".." }
            opoo "Skipping #{Formatter.identifier(action)} for relative path '#{path}'."
            next
          end

          if MacOS.undeletable?(resolved_path)
            opoo "Skipping #{Formatter.identifier(action)} for undeletable path '#{path}'."
            next
          end

          yield path, Pathname.glob(resolved_path)
        end
      end

      def uninstall_delete(*paths)
        return if paths.empty?

        ohai "Removing files:"
        each_resolved_path(:delete, paths) do |path, resolved_paths|
          puts path
          @command.run!("/usr/bin/xargs", args: ["-0", "--", "/bin/rm", "-r", "-f", "--"], input: resolved_paths.join("\0"), sudo: true)
        end
      end

      def uninstall_trash(*paths)
        return if paths.empty?

        resolved_paths = each_resolved_path(:trash, paths).to_a

        ohai "Trashing files:"
        puts resolved_paths.map(&:first)
        trash_paths(*resolved_paths.flat_map(&:last))
      end

      def trash_paths(*paths)
        @command.run!("/usr/bin/osascript", args: ["-e", <<-'EOS'.undent, *paths])
          on run argv
            repeat with i from 1 to (count argv)
              set item i of argv to (item i of argv as POSIX file)
            end repeat

            tell application "Finder"
              set trashedItems to (move argv to trash)
              set output to ""

              repeat with i from 1 to (count trashedItems)
                set trashedItem to POSIX path of (item i of trashedItems as string)
                set output to output & trashedItem
                if i < count trashedItems then
                  set output to output & (do shell script "printf \"\\0\"")
                end if
              end repeat

              return output
            end tell
          end run
        EOS
      end

      def uninstall_rmdir(*directories)
        return if directories.empty?

        ohai "Removing directories if empty:"
        each_resolved_path(:rmdir, directories) do |path, resolved_paths|
          puts path
          resolved_paths.select(&:directory?).each do |resolved_path|
            if (ds_store = resolved_path.join(".DS_Store")).exist?
              @command.run!("/bin/rm", args: ["-f", "--", ds_store], sudo: true, print_stderr: false)
            end

            @command.run("/bin/rmdir", args: ["--", resolved_path], sudo: true, print_stderr: false)
          end
        end
      end
    end
  end
end
