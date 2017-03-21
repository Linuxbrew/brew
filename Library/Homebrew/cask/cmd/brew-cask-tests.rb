require "English"

ENV["BUNDLE_GEMFILE"] = "#{HOMEBREW_LIBRARY_PATH}/cask/Gemfile"
ENV["BUNDLE_PATH"] = "#{HOMEBREW_LIBRARY_PATH}/vendor/bundle"

def run_tests(executable, files, args = [])
  opts = []
  opts << "--serialize-stdout" if ENV["CI"]

  system "bundle", "exec", executable, *opts, "--", *args, "--", *files
end

cask_root = Pathname.new(__FILE__).realpath.parent.parent
cask_root.cd do
  ENV["HOMEBREW_NO_ANALYTICS_THIS_RUN"] = "1"
  ENV["HOMEBREW_NO_EMOJI"] = "1"
  ENV.delete("HOMEBREW_CASK_OPTS")

  Homebrew.install_gem_setup_path! "bundler"
  unless quiet_system("bundle", "check")
    system "bundle", "install"
  end

  if ARGV.flag?("--coverage")
    ENV["HOMEBREW_TESTS_COVERAGE"] = "1"
    upload_coverage = ENV["CODECOV_TOKEN"] || ENV["TRAVIS"]
  end

  run_tests "parallel_rspec", Dir["spec/**/*_spec.rb"], %w[
    --color
    --require spec_helper
    --format progress
    --format ParallelTests::RSpec::RuntimeLogger
    --out tmp/parallel_runtime_rspec.log
  ]

  unless $CHILD_STATUS.success?
    Homebrew.failed = true
  end

  if upload_coverage
    puts "Submitting Codecov coverage..."
    system "bundle", "exec", "spec/upload_coverage.rb"
  end
end
