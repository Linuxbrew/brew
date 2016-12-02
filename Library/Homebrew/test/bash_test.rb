require "testing_env"

class BashTests < Homebrew::TestCase
  def assert_valid_bash_syntax(file)
    output = Utils.popen_read("/bin/bash -n #{file} 2>&1")
    assert $?.success?, output
  end

  def test_bin_brew
    assert_valid_bash_syntax HOMEBREW_LIBRARY_PATH.parent.parent/"bin/brew"
  end

  def test_bash_code
    Pathname.glob("#{HOMEBREW_LIBRARY_PATH}/**/*.sh").each do |pn|
      pn_relative = pn.relative_path_from(HOMEBREW_LIBRARY_PATH)
      next if pn_relative.to_s.start_with?("shims/", "test/", "vendor/")
      assert_valid_bash_syntax pn
    end
  end

  def test_bash_completion
    script = HOMEBREW_LIBRARY_PATH.parent.parent/"completions/bash/brew"
    assert_valid_bash_syntax script
  end

  def test_bash_shims
    # These have no file extension, but can be identified by their shebang.
    (HOMEBREW_LIBRARY_PATH/"shims").find do |pn|
      next if pn.directory? || pn.symlink?
      next unless pn.executable? && pn.read(12) == "#!/bin/bash\n"
      assert_valid_bash_syntax pn
    end
  end
end
