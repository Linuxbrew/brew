module Hbc
  class CLI
    class Create < AbstractCommand
      def initialize(*)
        super
        raise CaskUnspecifiedError if args.empty?
        raise ArgumentError, "Only one Cask can be created at a time." if args.count > 1
      end

      def run
        cask_token = args.first
        cask_path = CaskLoader.path(cask_token)
        raise CaskAlreadyCreatedError, cask_token if cask_path.exist?

        odebug "Creating Cask #{cask_token}"
        File.open(cask_path, "w") do |f|
          f.write self.class.template(cask_token)
        end

        exec_editor cask_path
      end

      def self.template(cask_token)
        <<-EOS.undent
          cask '#{cask_token}' do
            version ''
            sha256 ''

            url 'https://'
            name ''
            homepage ''

            app ''
          end
        EOS
      end

      def self.help
        "creates the given Cask and opens it in an editor"
      end
    end
  end
end
