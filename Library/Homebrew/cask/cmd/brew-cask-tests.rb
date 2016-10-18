require "English"

def run_tests(executable, files, args = [])
  opts = []
  opts << "--serialize-stdout" if ENV["CI"]

  system "bundle", "exec", executable, *opts, "--", *args, "--", *files
end

repo_root = Pathname(__FILE__).realpath.parent.parent
repo_root.cd do
  ENV["HOMEBREW_NO_ANALYTICS_THIS_RUN"] = "1"
  ENV["HOMEBREW_NO_EMOJI"] = "1"
  ENV.delete("HOMEBREW_CASK_OPTS")

  Homebrew.install_gem_setup_path! "bundler"
  unless quiet_system("bundle", "check")
    system "bundle", "install", "--path", "vendor/bundle"
  end

  rspec = ARGV.flag?("--rspec") || !ARGV.flag?("--minitest")
  minitest = ARGV.flag?("--minitest") || !ARGV.flag?("--rspec")

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
    system "bundle", "exec", "rake", "test:coverage:upload"
  end

  Homebrew.failed = !$CHILD_STATUS.success?
end
