require "testing_env"
require "utils/shell"

class ShellSmokeTest < Homebrew::TestCase
  def test_path_to_shell
    # raw command name
    assert_equal :bash, Utils::Shell.path_to_shell("bash")
    # full path
    assert_equal :bash, Utils::Shell.path_to_shell("/bin/bash")
    # versions
    assert_equal :zsh, Utils::Shell.path_to_shell("zsh-5.2")
    # strip newline too
    assert_equal :zsh, Utils::Shell.path_to_shell("zsh-5.2\n")
  end

  def test_path_to_shell_failure
    assert_equal nil, Utils::Shell.path_to_shell("")
    assert_equal nil, Utils::Shell.path_to_shell("@@@@@@")
    assert_equal nil, Utils::Shell.path_to_shell("invalid_shell-4.2")
  end

  def test_sh_quote
    assert_equal "''", Utils::Shell.sh_quote("")
    assert_equal "\\\\", Utils::Shell.sh_quote("\\")
    assert_equal "'\n'", Utils::Shell.sh_quote("\n")
    assert_equal "\\$", Utils::Shell.sh_quote("$")
    assert_equal "word", Utils::Shell.sh_quote("word")
  end

  def test_csh_quote
    assert_equal "''", Utils::Shell.csh_quote("")
    assert_equal "\\\\", Utils::Shell.csh_quote("\\")
    # note this test is different than for sh
    assert_equal "'\\\n'", Utils::Shell.csh_quote("\n")
    assert_equal "\\$", Utils::Shell.csh_quote("$")
    assert_equal "word", Utils::Shell.csh_quote("word")
  end

  def prepend_path_shell(shell, path, fragment)
    original_shell = ENV["SHELL"]
    ENV["SHELL"] = shell

    prepend_message = Utils::Shell.prepend_path_in_shell_profile(path)
    assert(
      prepend_message.start_with?(fragment),
      "#{shell}: expected #{prepend_message} to match #{fragment}"
    )

    ENV["SHELL"] = original_shell
  end

  def test_prepend_path_in_shell_profile
    prepend_path_shell "/bin/tcsh", "/path", "echo 'setenv PATH /path"

    prepend_path_shell "/bin/bash", "/path", "echo 'export PATH=\"/path"

    prepend_path_shell "/usr/local/bin/fish", "/path", "echo 'set -g fish_user_paths \"/path\" $fish_user_paths' >>"
  end
end
