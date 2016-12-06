require "testing_env"

class IntegrationCommandTestCreate < IntegrationCommandTestCase
  def test_create
    url = "file://#{TEST_FIXTURE_DIR}/tarballs/testball-0.1.tbz"
    cmd("create", url, "HOMEBREW_EDITOR" => "/bin/cat")

    formula_file = CoreTap.new.formula_dir/"testball.rb"
    assert formula_file.exist?, "The formula source should have been created"
    assert_match %Q(sha256 "#{TESTBALL_SHA256}"), formula_file.read
  end
end
