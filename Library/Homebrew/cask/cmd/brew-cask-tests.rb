require "English"

def run_tests(executable, files, args = [])
  system "bundle", "exec", executable, "--", *args, "--", *files
end

repo_root = Pathname(__FILE__).realpath.parent.parent
repo_root.cd do
  ENV["HOMEBREW_NO_ANALYTICS_THIS_RUN"] = "1"

  Homebrew.install_gem_setup_path! "bundler"
  unless quiet_system("bundle", "check")
    system "bundle", "install", "--path", "vendor/bundle"
  end

  rspec = ARGV.flag?("--rspec") || !ARGV.flag?("--minitest")
  minitest = ARGV.flag?("--minitest") || !ARGV.flag?("--rspec")

  # TODO: setting the --seed here is an ugly temporary hack, to remain only
  #       until test-suite glitches are fixed.
  ENV["TESTOPTS"] = "--seed=14830" if ENV["TRAVIS"]

  ENV["HOMEBREW_TESTS_COVERAGE"] = "1" if ARGV.flag?("--coverage")

  if rspec
    run_tests "parallel_rspec", Dir["spec/**/*_spec.rb"], %w[
      --format progress
      --format ParallelTests::RSpec::RuntimeLogger
      --out tmp/parallel_runtime_rspec.log
    ]
  end

  if minitest
    run_tests "parallel_test", Dir["test/**/*_test.rb"]
  end

  if ENV["CODECOV_TOKEN"]
    require "simplecov"
    require "codecov"
    formatter = SimpleCov::Formatter::Codecov.new
    formatter.format(SimpleCov::ResultMerger.merged_result)
  end

  Homebrew.failed = !$CHILD_STATUS.success?
end
