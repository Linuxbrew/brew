require "pathname"
require "open3"

def curl_args(extra_args = [])
  curl = Pathname.new ENV["HOMEBREW_CURL"]
  curl = Pathname.new "/usr/bin/curl" unless curl.exist?
  raise "#{curl} is not executable" unless curl.exist? && curl.executable?

  flags = HOMEBREW_CURL_ARGS
  flags -= ["--progress-bar"] if ARGV.verbose?

  args = [curl.to_s] + flags + extra_args
  args << "--verbose" if ENV["HOMEBREW_CURL_VERBOSE"]
  args << "--silent" if !$stdout.tty? || ENV["TRAVIS"]
  args
end

def curl(*args)
  safe_system(*curl_args(args))
end

def curl_output(*args)
  curl_args = curl_args(args)
  curl_args -= ["--fail", "--silent"]
  Open3.popen3(*curl_args) do |_, stdout, stderr, wait_thread|
    [stdout.read, stderr.read, wait_thread.value]
  end
end
