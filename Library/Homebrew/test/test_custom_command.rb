require "helper/integration_command_test_case"

class IntegrationCommandTestCustomCommand < IntegrationCommandTestCase
  def test_custom_command
    mktmpdir do |path|
      cmd = "int-test-#{rand}"
      file = "#{path}/brew-#{cmd}"

      File.open(file, "w") { |f| f.write "#!/bin/sh\necho 'I am #{cmd}'\n" }
      FileUtils.chmod 0777, file

      assert_match "I am #{cmd}",
        cmd(cmd, "PATH" => "#{path}#{File::PATH_SEPARATOR}#{ENV["PATH"]}")
    end
  end
end
