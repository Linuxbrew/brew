require "integration_cmds_tests"

class IntegrationCommandTestOptions < IntegrationCommandTests
  def test_options
    setup_test_formula "testball", <<-EOS.undent
      depends_on "bar" => :recommended
    EOS

    assert_equal "--with-foo\n\tBuild with foo\n--without-bar\n\tBuild without bar support",
      cmd_output("options", "testball").chomp
  end
end
