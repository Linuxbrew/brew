module Hbc
  class CLI
    class Uninstall < Base
      def self.run(*args)
        cask_tokens = cask_tokens_from(args)
        raise CaskUnspecifiedError if cask_tokens.empty?
        force = args.include? "--force"

        cask_tokens.each do |cask_token|
          odebug "Uninstalling Cask #{cask_token}"
          cask = CaskLoader.load(cask_token)

          raise CaskNotInstalledError, cask unless cask.installed? || force

          if cask.installed? && !cask.installed_caskfile.nil?
            # use the same cask file that was used for installation, if possible
            cask = CaskLoader.load_from_file(cask.installed_caskfile) if cask.installed_caskfile.exist?
          end

          Installer.new(cask, binaries: CLI.binaries?, force: force).uninstall

          next if (versions = cask.versions).empty?

          single = versions.count == 1

          puts <<-EOS.undent
            #{cask_token} #{versions.join(", ")} #{single ? "is" : "are"} still installed.
            Remove #{single ? "it" : "them all"} with `brew cask uninstall --force #{cask_token}`.
          EOS
        end
      end

      def self.help
        "uninstalls the given Cask"
      end
    end
  end
end
