require "testing_env"
require "cmd/uninstall"

class UninstallTests < Homebrew::TestCase
  def setup
    super

    @dependency = formula("dependency") { url "f-1" }
    @dependent = formula("dependent") do
      url "f-1"
      depends_on "dependency"
    end

    [@dependency, @dependent].each do |f|
      f.installed_prefix.mkpath
      Keg.new(f.installed_prefix).optlink
    end

    tab = Tab.empty
    tab.homebrew_version = "1.1.6"
    tab.tabfile = @dependent.installed_prefix/Tab::FILENAME
    tab.runtime_dependencies = [
      { "full_name" => "dependency", "version" => "1" },
    ]
    tab.write

    stub_formula_loader @dependency
    stub_formula_loader @dependent
  end

  def teardown
    Homebrew.failed = false
    super
  end

  def handle_unsatisfied_dependents
    capture_stderr do
      opts = { @dependency.rack => [Keg.new(@dependency.installed_prefix)] }
      Homebrew.handle_unsatisfied_dependents(opts)
    end
  end

  def test_check_for_testball_f2s_when_developer
    assert_match "Warning", handle_unsatisfied_dependents
    refute_predicate Homebrew, :failed?
  end

  def test_check_for_dependents_when_not_developer
    run_as_not_developer do
      assert_match "Error", handle_unsatisfied_dependents
      assert_predicate Homebrew, :failed?
    end
  end

  def test_check_for_dependents_when_ignore_dependencies
    ARGV << "--ignore-dependencies"
    run_as_not_developer do
      assert_empty handle_unsatisfied_dependents
      refute_predicate Homebrew, :failed?
    end
  end
end

class IntegrationCommandTestUninstall < IntegrationCommandTestCase
  def test_uninstall
    cmd("install", testball)
    assert_match "Uninstalling testball", cmd("uninstall", "--force", testball)
  end
end
