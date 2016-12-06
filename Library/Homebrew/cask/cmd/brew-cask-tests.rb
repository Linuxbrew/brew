require "English"

ENV["BUNDLE_GEMFILE"] = "#{HOMEBREW_LIBRARY_PATH}/cask/Gemfile"
ENV["BUNDLE_PATH"] = "#{HOMEBREW_LIBRARY_PATH}/vendor/bundle"

def run_tests(executable, files, args = [])
  opts = []
  opts << "--serialize-stdout" if ENV["CI"]

  system "bundle", "exec", executable, *opts, "--", *args, "--", *files
end

repo_root = Pathname.new(__FILE__).realpath.parent.parent
repo_root.cd do
  ENV["HOMEBREW_NO_ANALYTICS_THIS_RUN"] = "1"
  ENV["HOMEBREW_NO_EMOJI"] = "1"
  ENV.delete("HOMEBREW_CASK_OPTS")

  Homebrew.install_gem_setup_path! "bundler"
  unless quiet_system("bundle", "check")
    system "bundle", "install"
  end

  rspec = ARGV.flag?("--rspec") || !ARGV.flag?("--minitest")
  minitest = ARGV.flag?("--minitest") || !ARGV.flag?("--rspec")

  ENV["HOMEBREW_TESTS_COVERAGE"] = "1" if ARGV.flag?("--coverage")

  failed = false

  if rspec
    run_tests "parallel_rspec", Dir["spec/**/*_spec.rb"], %w[
      --color
      --require spec_helper
      --format progress
      --format ParallelTests::RSpec::RuntimeLogger
      --out tmp/parallel_runtime_rspec.log
    ]
    failed ||= !$CHILD_STATUS.success?
  end

  if minitest
    run_tests "parallel_test", Dir["test/**/*_test.rb"]
    failed ||= !$CHILD_STATUS.success?
  end

  Homebrew.failed = failed

  if ENV["CODECOV_TOKEN"]
    system "bundle", "exec", "rake", "test:coverage:upload"
  end
end
