module Hbc
  class CLI
    class Info < Base
      def self.run(*args)
        cask_tokens = cask_tokens_from(args)
        raise CaskUnspecifiedError if cask_tokens.empty?
        cask_tokens.each do |cask_token|
          odebug "Getting info for Cask #{cask_token}"
          cask = Hbc.load(cask_token)

          info(cask)
        end
      end

      def self.help
        "displays information about the given Cask"
      end

      def self.info(cask)
        puts "#{cask.token}: #{cask.version}"
        puts Formatter.url(cask.homepage) if cask.homepage
        installation_info(cask)
        puts "From: #{Formatter.url(repo_info(cask))}"
        name_info(cask)
        artifact_info(cask)
        Installer.print_caveats(cask)
      end

      def self.formatted_url(url)
        "#{Tty.underline}#{url}#{Tty.reset}"
      end

      def self.installation_info(cask)
        if cask.installed?
          cask.versions.each do |version|
            versioned_staged_path = cask.caskroom_path.join(version)

            puts versioned_staged_path.to_s
              .concat(" (")
              .concat(versioned_staged_path.exist? ? versioned_staged_path.abv : Formatter.error("does not exist"))
              .concat(")")
          end
        else
          puts "Not installed"
        end
      end

      def self.name_info(cask)
        ohai cask.name.size > 1 ? "Names" : "Name"
        puts cask.name.empty? ? Formatter.error("None") : cask.name
      end

      def self.repo_info(cask)
        user, repo, token = QualifiedToken.parse(Hbc.all_tokens.detect { |t| t.split("/").last == cask.token })
        remote_tap = Tap.fetch(user, repo)

        if remote_tap.custom_remote? && !remote_tap.remote.nil?
          return remote_tap.remote.to_s
        end

        "#{remote_tap.default_remote}/blob/master/Casks/#{token}.rb"
      end

      def self.artifact_info(cask)
        ohai "Artifacts"
        DSL::ORDINARY_ARTIFACT_TYPES.each do |type|
          next if cask.artifacts[type].empty?
          cask.artifacts[type].each do |artifact|
            activatable_item = type == :stage_only ? "<none>" : artifact.first
            puts "#{activatable_item} (#{type})"
          end
        end
      end
    end
  end
end
