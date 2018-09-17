require "json"

module Cask
  class Cmd
    class Info < AbstractCommand
      option "--json=VERSION", :json

      def initialize(*)
        super
        raise CaskUnspecifiedError if args.empty?
      end

      def run
        if json == "v1"
          puts JSON.generate(casks.map(&:to_h))
        else
          casks.each do |cask|
            odebug "Getting info for Cask #{cask}"
            self.class.info(cask)
          end
        end
      end

      def self.help
        "displays information about the given Cask"
      end

      def self.info(cask)
        title_info(cask)
        puts Formatter.url(cask.homepage) if cask.homepage
        installation_info(cask)
        repo_info(cask)
        name_info(cask)
        language_info(cask)
        artifact_info(cask)
        Installer.print_caveats(cask)
      end

      def self.title_info(cask)
        title = "#{cask.token}: #{cask.version}"
        title += " (auto_updates)" if cask.auto_updates
        puts title
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
        ohai((cask.name.size > 1) ? "Names" : "Name")
        puts cask.name.empty? ? Formatter.error("None") : cask.name
      end

      def self.language_info(cask)
        return if cask.languages.empty?

        ohai "Languages"
        puts cask.languages.join(", ")
      end

      def self.repo_info(cask)
        return if cask.tap.nil?

        url = if cask.tap.custom_remote? && !cask.tap.remote.nil?
          cask.tap.remote
        else
          "#{cask.tap.default_remote}/blob/master/Casks/#{cask.token}.rb"
        end

        puts "From: #{Formatter.url(url)}"
      end

      def self.artifact_info(cask)
        ohai "Artifacts"
        cask.artifacts.each do |artifact|
          next unless artifact.respond_to?(:install_phase)
          next unless DSL::ORDINARY_ARTIFACT_CLASSES.include?(artifact.class)

          puts artifact.to_s
        end
      end
    end
  end
end
