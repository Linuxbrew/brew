require "hbc/artifact/base"

module Hbc
  module Artifact
    class Installer < Base
      def install_phase
        @cask.artifacts[self.class.artifact_dsl_key].each do |artifact|
          if artifact.manual
            puts <<-EOS.undent
              To complete the installation of Cask #{@cask}, you must also
              run the installer at

                '#{@cask.staged_path.join(artifact.manual)}'

            EOS
          else
            executable, script_arguments = self.class.read_script_arguments(artifact.script,
                                                                            self.class.artifact_dsl_key.to_s,
                                                                            { must_succeed: true, sudo: false },
                                                                            print_stdout: true)
            ohai "Running #{self.class.artifact_dsl_key} script #{executable}"
            raise CaskInvalidError.new(@cask, "#{self.class.artifact_dsl_key} missing executable") if executable.nil?
            executable_path = @cask.staged_path.join(executable)
            @command.run("/bin/chmod", args: ["--", "+x", executable_path]) if File.exist?(executable_path)
            @command.run(executable_path, script_arguments)
          end
        end
      end
    end
  end
end
