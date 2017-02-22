require "rspec"
require "open3"

RSpec::Matchers.define_negated_matcher :not_to_output, :output
RSpec::Matchers.define_negated_matcher :be_a_failure, :be_a_success

RSpec.shared_context "integration test" do
  extend RSpec::Matchers::DSL

  matcher :be_a_success do
    match do |actual|
      status = actual.is_a?(Proc) ? actual.call : actual
      status.respond_to?(:success?) && status.success?
    end

    def supports_block_expectations?
      true
    end

    # It needs to be nested like this:
    #
    #   expect {
    #     expect {
    #       # command
    #     }.to be_a_success
    #   }.to output(something).to_stdout
    #
    # rather than this:
    #
    #   expect {
    #     expect {
    #       # command
    #     }.to output(something).to_stdout
    #   }.to be_a_success
    #
    def expects_call_stack_jump?
      true
    end
  end

  before(:each) do
    (HOMEBREW_PREFIX/"bin").mkpath
    FileUtils.touch HOMEBREW_PREFIX/"bin/brew"
  end

  after(:each) do
    FileUtils.rm HOMEBREW_PREFIX/"bin/brew"
    FileUtils.rmdir HOMEBREW_PREFIX/"bin"
  end

  # Generate unique ID to be able to
  # properly merge coverage results.
  def command_id_from_args(args)
    @command_count ||= 0
    pretty_args = args.join(" ").gsub(TEST_TMPDIR, "@TMPDIR@")
    file_and_line = caller[1].sub(/(.*\d+):.*/, '\1')
                             .sub("#{HOMEBREW_LIBRARY_PATH}/test/", "")
    "#{file_and_line}:brew #{pretty_args}:#{@command_count += 1}"
  end

  # Runs a `brew` command with the test configuration
  # and with coverage reporting enabled.
  def brew(*args)
    env = args.last.is_a?(Hash) ? args.pop : {}

    env.merge!(
      "HOMEBREW_BREW_FILE" => HOMEBREW_PREFIX/"bin/brew",
      "HOMEBREW_INTEGRATION_TEST" => command_id_from_args(args),
      "HOMEBREW_TEST_TMPDIR" => TEST_TMPDIR,
      "HOMEBREW_DEVELOPER" => ENV["HOMEBREW_DEVELOPER"],
    )

    ruby_args = [
      "-W0",
      "-I", "#{HOMEBREW_LIBRARY_PATH}/test/support/lib",
      "-I", HOMEBREW_LIBRARY_PATH.to_s,
      "-rconfig"
    ]
    ruby_args << "-rsimplecov" if ENV["HOMEBREW_TESTS_COVERAGE"]
    ruby_args << "-rtest/support/helper/integration_mocks"
    ruby_args << (HOMEBREW_LIBRARY_PATH/"brew.rb").resolved_path.to_s

    Bundler.with_original_env do
      stdout, stderr, status = Open3.capture3(env, RUBY_PATH, *ruby_args, *args)
      $stdout.print stdout
      $stderr.print stderr
      status
    end
  end
end

RSpec.configure do |config|
  config.include_context "integration test", :integration_test
end
