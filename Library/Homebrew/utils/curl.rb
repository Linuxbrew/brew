require "pathname"

def curl_args(extra_args=[])
  curl = Pathname.new ENV["HOMEBREW_CURL"]
  curl = Pathname.new "/usr/bin/curl" unless curl.exist?
  raise "#{curl} is not executable" unless curl.exist? && curl.executable?

  flags = HOMEBREW_CURL_ARGS
  flags -= ["--progress-bar"] if ARGV.verbose?

  args = ["#{curl}"] + flags + extra_args
  args << "--verbose" if ENV["HOMEBREW_CURL_VERBOSE"]
  args << "--silent" if !$stdout.tty? || ENV["TRAVIS"]
  args
end

def curl(*args)
  safe_system(*curl_args(args))
end

def curl_output(*args)
  curl_args = curl_args(args) - ["--fail"]
  Utils.popen_read_text(*curl_args)
end
