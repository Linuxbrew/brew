require "open3"

def curl_executable
  @curl ||= [
    ENV["HOMEBREW_CURL"],
    which("curl"),
    "/usr/bin/curl",
  ].compact.map { |c| Pathname(c) }.find(&:executable?)
  raise "no executable curl was found" unless @curl

  @curl
end

def curl_args(*extra_args, show_output: false, user_agent: :default)
  args = []

  # do not load .curlrc unless requested (must be the first argument)
  args << "-q" unless ENV["HOMEBREW_CURLRC"]

  args << "--show-error"

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
    args << "--silent" if !$stdout.tty? || ENV["HOMEBREW_TRAVIS_CI"]
  end

  args + extra_args
end

def curl(*args)
  # SSL_CERT_FILE can be incorrectly set by users or portable-ruby and screw
  # with SSL downloads so unset it here.
  system_command! curl_executable,
                  args: curl_args(*args),
                  print_stdout: true,
                  env: { "SSL_CERT_FILE" => nil }
end

def curl_download(*args, to: nil, **options)
  destination = Pathname(to)
  destination.dirname.mkpath

  continue_at = if destination.exist? &&
                   curl_output("--location", "--head", "--range", "0-1",
                               "--write-out", "%{http_code}",
                               "--output", "/dev/null", *args, **options).stdout.to_i == 206 # Partial Content
    "-"
  else
    0
  end

  curl("--location", "--remote-time", "--continue-at", continue_at.to_s, "--output", destination, *args, **options)
end

def curl_output(*args, **options)
  system_command(curl_executable,
                 args: curl_args(*args, show_output: true, **options),
                 print_stderr: false)
end

def curl_check_http_content(url, user_agents: [:default], check_content: false, strict: false, require_http: false)
  return unless url.start_with? "http"

  details = nil
  user_agent = nil
  hash_needed = url.start_with?("http:") && !require_http
  user_agents.each do |ua|
    details = curl_http_content_headers_and_checksum(url, hash_needed: hash_needed, user_agent: ua)
    user_agent = ua
    break if details[:status].to_s.start_with?("2")
  end

  unless details[:status]
    # Hack around https://github.com/Homebrew/brew/issues/3199
    return if MacOS.version == :el_capitan

    return "The URL #{url} is not reachable"
  end

  unless details[:status].start_with? "2"
    return "The URL #{url} is not reachable (HTTP status code #{details[:status]})"
  end

  return unless hash_needed

  secure_url = url.sub "http", "https"
  secure_details =
    curl_http_content_headers_and_checksum(secure_url, hash_needed: true, user_agent: user_agent)

  if !details[:status].to_s.start_with?("2") ||
     !secure_details[:status].to_s.start_with?("2")
    return
  end

  etag_match = details[:etag] &&
               details[:etag] == secure_details[:etag]
  content_length_match =
    details[:content_length] &&
    details[:content_length] == secure_details[:content_length]
  file_match = details[:file_hash] == secure_details[:file_hash]

  if etag_match || content_length_match || file_match
    return "The URL #{url} should use HTTPS rather than HTTP"
  end

  return unless check_content

  no_protocol_file_contents = %r{https?:\\?/\\?/}
  details[:file] = details[:file].gsub(no_protocol_file_contents, "/")
  secure_details[:file] = secure_details[:file].gsub(no_protocol_file_contents, "/")

  # Check for the same content after removing all protocols
  if details[:file] == secure_details[:file]
    return "The URL #{url} should use HTTPS rather than HTTP"
  end

  return unless strict

  # Same size, different content after normalization
  # (typical causes: Generated ID, Timestamp, Unix time)
  if details[:file].length == secure_details[:file].length
    return "The URL #{url} may be able to use HTTPS rather than HTTP. Please verify it in a browser."
  end

  lenratio = (100 * secure_details[:file].length / details[:file].length).to_i
  return unless (90..110).cover?(lenratio)

  "The URL #{url} may be able to use HTTPS rather than HTTP. Please verify it in a browser."
end

def curl_http_content_headers_and_checksum(url, hash_needed: false, user_agent: :default)
  max_time = hash_needed ? "600" : "25"
  output, = curl_output(
    "--connect-timeout", "15", "--include", "--max-time", max_time, "--location", url,
    user_agent: user_agent
  )

  status_code = :unknown
  while status_code == :unknown || status_code.to_s.start_with?("3")
    headers, _, output = output.partition("\r\n\r\n")
    status_code = headers[%r{HTTP\/.* (\d+)}, 1]
  end

  output_hash = Digest::SHA256.digest(output) if hash_needed

  {
    status: status_code,
    etag: headers[%r{ETag: ([wW]\/)?"(([^"]|\\")*)"}, 2],
    content_length: headers[/Content-Length: (\d+)/, 1],
    file_hash: output_hash,
    file: output,
  }
end
