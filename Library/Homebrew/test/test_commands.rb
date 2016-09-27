require "testing_env"
require "cmd/command"
require "cmd/commands"
require "fileutils"
require "helper/integration_command_test_case"

class IntegrationCommandTestCommands < IntegrationCommandTestCase
  def test_commands
    assert_match "Built-in commands",
                 cmd("commands")
  end
end

class CommandsTests < Homebrew::TestCase
  def setup
    @cmds = [
      # internal commands
      HOMEBREW_LIBRARY_PATH/"cmd/rbcmd.rb",
      HOMEBREW_LIBRARY_PATH/"cmd/shcmd.sh",

      # internal development commands
      HOMEBREW_LIBRARY_PATH/"dev-cmd/rbdevcmd.rb",
      HOMEBREW_LIBRARY_PATH/"dev-cmd/shdevcmd.sh",
    ]

    @cmds.each { |f| FileUtils.touch f }
  end

  def teardown
    @cmds.each(&:unlink)
  end

  def test_internal_commands
    cmds = Homebrew.internal_commands
    assert cmds.include?("rbcmd"), "Ruby commands files should be recognized"
    assert cmds.include?("shcmd"), "Shell commands files should be recognized"
    refute cmds.include?("rbdevcmd"), "Dev commands shouldn't be included"
  end

  def test_internal_developer_commands
    cmds = Homebrew.internal_developer_commands
    assert cmds.include?("rbdevcmd"), "Ruby commands files should be recognized"
    assert cmds.include?("shdevcmd"), "Shell commands files should be recognized"
    refute cmds.include?("rbcmd"), "Non-dev commands shouldn't be included"
  end

  def test_external_commands
    env = ENV.to_hash

    mktmpdir do |dir|
      %w[brew-t1 brew-t2.rb brew-t3.py].each do |file|
        path = "#{dir}/#{file}"
        FileUtils.touch path
        FileUtils.chmod 0755, path
      end

      FileUtils.touch "#{dir}/brew-t4"

      ENV["PATH"] += "#{File::PATH_SEPARATOR}#{dir}"
      cmds = Homebrew.external_commands

      assert cmds.include?("t1"), "Executable files should be included"
      assert cmds.include?("t2"), "Executable Ruby files should be included"
      refute cmds.include?("t3"),
        "Executable files with a non Ruby extension shoudn't be included"
      refute cmds.include?("t4"), "Non-executable files shouldn't be included"
    end
  ensure
    ENV.replace(env)
  end

  def test_internal_command_path
    assert_equal HOMEBREW_LIBRARY_PATH/"cmd/rbcmd.rb",
                 Commands.path("rbcmd")
    assert_equal HOMEBREW_LIBRARY_PATH/"cmd/shcmd.sh",
                 Commands.path("shcmd")
    assert_nil Commands.path("idontexist1234")
  end

  def test_internal_dev_command_path
    assert_equal HOMEBREW_LIBRARY_PATH/"dev-cmd/rbdevcmd.rb",
                 Commands.path("rbdevcmd")
    assert_equal HOMEBREW_LIBRARY_PATH/"dev-cmd/shdevcmd.sh",
                 Commands.path("shdevcmd")
  end
end
