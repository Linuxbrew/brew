require "testing_env"
require "requirements/gpg2_requirement"
require "fileutils"

class GPG2RequirementTests < Homebrew::TestCase
  def setup
    super
    @dir = Pathname.new(mktmpdir)
    (@dir/"bin/gpg").write <<-EOS.undent
      #!/bin/bash
      echo 2.0.30
    EOS
    FileUtils.chmod 0755, @dir/"bin/gpg"
  end

  def teardown
    FileUtils.rm_rf @dir
    super
  end

  def test_satisfied
    ENV["PATH"] = @dir/"bin"
    assert_predicate GPG2Requirement.new, :satisfied?
  end
end
