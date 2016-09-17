require "pathname"

require "testing_env"
require "dev-cmd/test-bot"

class TestbotCommandTests < Homebrew::TestCase
  def test_resolve_test_tap
    tap = Homebrew.resolve_test_tap
    assert_nil tap, "Should return nil if no tap slug provided"

    slug = "spam/homebrew-eggs"
    url = "https://github.com/#{slug}.git"
    environments = [
      { "TRAVIS_REPO_SLUG" => slug },
      { "UPSTREAM_BOT_PARAMS" => "--tap=#{slug}" },
      { "UPSTREAM_BOT_PARAMS" => "--tap=spam/eggs" },
      { "UPSTREAM_GIT_URL" => url },
      { "GIT_URL" => url },
    ]

    predicate = proc do |message|
      tap = Homebrew.resolve_test_tap
      assert_kind_of Tap, tap, message
      assert_equal tap.user, "spam", message
      assert_equal tap.repo, "eggs", message
    end

    environments.each do |pair|
      with_environment(pair) do
        predicate.call pair.to_s
      end
    end

    ARGV.expects(:value).with("tap").returns(slug)
    predicate.call "ARGV"
  end
end

class TestbotStepTests < Homebrew::TestCase
  def run
    [nil, "1"].each do |travis|
      with_environment("TRAVIS" => travis) { super }
    end
    self
  end

  def teardown
    unless passed?
      raise "INFO: Previous test failed with ENV['TRAVIS'] = #{ENV["TRAVIS"].inspect}"
    end
  end

  def stub_test_instance
    stub(
      category: "stub",
      log_root: Pathname.pwd
    )
  end

  def test_step_run_measures_execution_time
    step = Homebrew::Step.new stub_test_instance, %w[sleep 0.1]
    shutup do
      step.run
    end
    assert_operator step.time, :>, 0.1
    assert_operator step.time, :<, 1
    assert_equal step.passed?, true
  end

  def test_step_run_observes_failure
    step = Homebrew::Step.new stub_test_instance, ["false", ""]
    shutup do
      step.run
    end
    assert_equal step.passed?, false
    assert_equal step.failed?, true
  end

  def test_step_dry_run_is_dry_and_always_succeeds
    step = Homebrew::Step.new stub_test_instance, ["false", ""]
    ARGV.expects(:include?).with("--dry-run").returns(true)
    step.stubs(:fork).raises("Dry run isn't dry!")
    shutup do
      step.run
    end
    assert_equal step.passed?, true
  end

  def test_step_fail_fast_exits_on_failure
    step = Homebrew::Step.new stub_test_instance, ["false", ""]
    ARGV.stubs(:include?).returns(false)
    ARGV.expects(:include?).with("--fail-fast").returns(true)
    step.expects(:exit).with(1).returns(nil)
    shutup do
      step.run
    end
    assert_equal step.passed?, false
  end
end
