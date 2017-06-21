module Hbc
  class CLI
    class List < AbstractCommand
      option "-1", :one, false
      option "--versions", :versions, false

      option "-l", (lambda do |*|
        one = true # rubocop:disable Lint/UselessAssignment
        opoo "Option -l is obsolete! Implying option -1."
      end)

      def run
        retval = args.any? ? list : list_installed
        # retval is ternary: true/false/nil
        if retval.nil? && args.none?
          opoo "nothing to list" # special case: avoid exit code
        elsif retval.nil?
          raise CaskError, "nothing to list"
        elsif !retval
          raise CaskError, "listing incomplete"
        end
      end

      def list
        count = 0

        args.each do |cask_token|
          odebug "Listing files for Cask #{cask_token}"
          begin
            cask = CaskLoader.load(cask_token)

            if cask.installed?
              if one?
                puts cask.token
              elsif versions?
                puts self.class.format_versioned(cask)
              else
                cask = CaskLoader.load_from_file(cask.installed_caskfile)
                self.class.list_artifacts(cask)
              end

              count += 1
            else
              opoo "#{cask} is not installed"
            end
          rescue CaskUnavailableError => e
            onoe e
          end
        end

        count.zero? ? nil : count == args.length
      end

      def self.list_artifacts(cask)
        Artifact.for_cask(cask).each do |artifact|
          summary = artifact.summary
          ohai summary[:english_description], summary[:contents] unless summary.empty?
        end
      end

      def list_installed
        installed_casks = Hbc.installed

        if one?
          puts installed_casks.map(&:to_s)
        elsif versions?
          puts installed_casks.map(&self.class.method(:format_versioned))
        elsif !installed_casks.empty?
          puts Formatter.columns(installed_casks.map(&:to_s))
        end

        installed_casks.empty? ? nil : true
      end

      def self.format_versioned(cask)
        cask.to_s.concat(cask.versions.map(&:to_s).join(" ").prepend(" "))
      end

      def self.help
        "with no args, lists installed Casks; given installed Casks, lists staged files"
      end

      def self.needs_init?
        true
      end
    end
  end
end
