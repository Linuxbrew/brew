require "helper/integration_command_test_case"

class IntegrationCommandTestPrune < IntegrationCommandTestCase
  def test_prune
    share = (HOMEBREW_PREFIX/"share")

    (share/"pruneable/directory/here").mkpath
    (share/"notpruneable/file").write "I'm here"
    FileUtils.ln_s "/i/dont/exist/no/really/i/dont", share/"pruneable_symlink"

    assert_match %r{Would remove \(empty directory\): .*/pruneable/directory/here},
      cmd("prune", "--dry-run")
    assert_match "Pruned 1 symbolic links and 3 directories",
      cmd("prune")
    refute((share/"pruneable").directory?)
    assert((share/"notpruneable").directory?)
    refute((share/"pruneable_symlink").symlink?)

    assert_match "Nothing pruned", cmd("prune", "--verbose")
  end
end
