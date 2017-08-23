require "pathname"
require "open3"

def curl_executable
  curl = Pathname.new ENV["HOMEBREW_CURL"]
  curl = Pathname.new "/usr/bin/curl" unless curl.exist?
  return curl if curl.executable?
  raise "#{curl} is not executable"
end

def curl_args(*extra_args, show_output: false, user_agent: :default)
  args = [
    curl_executable.to_s,
    "--show-error",
  ]

  args << "--user-agent" << case user_agent
  when :browser, :fake
    HOMEBREW_USER_AGENT_FAKE_SAFARI
  when :default
    HOMEBREW_USER_AGENT_CURL
  else
    user_agent
  end

  unless show_output
    args << "--fail"
    args << "--progress-bar" unless ARGV.verbose?
    args << "--verbose" if ENV["HOMEBREW_CURL_VERBOSE"]
    args << "--silent" if !$stdout.tty? || ENV["TRAVIS"]
  end

  args + extra_args
end

def curl(*args)
  safe_system(*curl_args(*args))
end

def curl_download(*args, to: nil, continue_at: "-", **options)
  curl("--location", "--remote-time", "--continue-at", continue_at.to_s, "--output", to, *args, **options)
rescue ErrorDuringExecution
  # `curl` error 33: HTTP server doesn't seem to support byte ranges. Cannot resume.
  if $CHILD_STATUS.exitstatus == 33 && continue_at == "-"
    continue_at = 0
    retry
  end

  raise
end

def curl_output(*args, **options)
  Open3.capture3(*curl_args(*args, show_output: true, **options))
end
