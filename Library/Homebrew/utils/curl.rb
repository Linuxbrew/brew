require "pathname"
require "open3"

def curl_args(options = {})
  curl = Pathname.new ENV["HOMEBREW_CURL"]
  curl = Pathname.new "/usr/bin/curl" unless curl.exist?
  raise "#{curl} is not executable" unless curl.exist? && curl.executable?

  args = [
    curl.to_s,
    "--remote-time",
    "--location",
  ]

  case options[:user_agent]
  when :browser
    args << "--user-agent" << HOMEBREW_USER_AGENT_FAKE_SAFARI
  else
    args << "--user-agent" << HOMEBREW_USER_AGENT_CURL
  end

  unless options[:show_output]
    args << "--progress-bar" unless ARGV.verbose?
    args << "--verbose" if ENV["HOMEBREW_CURL_VERBOSE"]
    args << "--fail"
    args << "--silent" if !$stdout.tty? || ENV["TRAVIS"]
  end

  args += options[:extra_args] if options[:extra_args]
  args
end

def curl(*args)
  safe_system(*curl_args(extra_args: args))
end

def curl_output(*args)
  curl_args = curl_args(extra_args: args, show_output: true)
  Open3.popen3(*curl_args) do |_, stdout, stderr, wait_thread|
    [stdout.read, stderr.read, wait_thread.value]
  end
end
