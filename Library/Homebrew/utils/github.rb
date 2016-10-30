require "uri"
require "tempfile"

module GitHub
  module_function

  ISSUES_URI = URI.parse("https://api.github.com/search/issues")

  CREATE_GIST_SCOPES = ["gist"].freeze
  CREATE_ISSUE_SCOPES = ["public_repo"].freeze
  ALL_SCOPES = (CREATE_GIST_SCOPES + CREATE_ISSUE_SCOPES).freeze
  ALL_SCOPES_URL = Formatter.url("https://github.com/settings/tokens/new?scopes=#{ALL_SCOPES.join(",")}&description=Homebrew").freeze

  Error = Class.new(RuntimeError)
  HTTPNotFoundError = Class.new(Error)

  class RateLimitExceededError < Error
    def initialize(reset, error)
      super <<-EOS.undent
        GitHub API Error: #{error}
        Try again in #{pretty_ratelimit_reset(reset)}, or create a personal access token:
          #{ALL_SCOPES_URL}
        and then set the token as: export HOMEBREW_GITHUB_API_TOKEN="your_new_token"
      EOS
    end

    def pretty_ratelimit_reset(reset)
      pretty_duration(Time.at(reset) - Time.now)
    end
  end

  class AuthenticationFailedError < Error
    def initialize(error)
      message = "GitHub #{error}\n"
      if ENV["HOMEBREW_GITHUB_API_TOKEN"]
        message << <<-EOS.undent
          HOMEBREW_GITHUB_API_TOKEN may be invalid or expired; check:
          #{Formatter.url("https://github.com/settings/tokens")}
        EOS
      else
        message << <<-EOS.undent
          The GitHub credentials in the macOS keychain may be invalid.
          Clear them with:
            printf "protocol=https\\nhost=github.com\\n" | git credential-osxkeychain erase
          Or create a personal access token:
            #{ALL_SCOPES_URL}
          and then set the token as: export HOMEBREW_GITHUB_API_TOKEN="your_new_token"
        EOS
      end
      super message
    end
  end

  def api_credentials
    @api_credentials ||= begin
      if ENV["HOMEBREW_GITHUB_API_TOKEN"]
        ENV["HOMEBREW_GITHUB_API_TOKEN"]
      elsif ENV["HOMEBREW_GITHUB_API_USERNAME"] && ENV["HOMEBREW_GITHUB_API_PASSWORD"]
        [ENV["HOMEBREW_GITHUB_API_PASSWORD"], ENV["HOMEBREW_GITHUB_API_USERNAME"]]
      else
        github_credentials = api_credentials_from_keychain
        github_username = github_credentials[/username=(.+)/, 1]
        github_password = github_credentials[/password=(.+)/, 1]
        if github_username && github_password
          [github_password, github_username]
        else
          []
        end
      end
    end
  end

  def api_credentials_from_keychain
    Utils.popen(["git", "credential-osxkeychain", "get"], "w+") do |pipe|
      pipe.write "protocol=https\nhost=github.com\n"
      pipe.close_write
      pipe.read
    end
  rescue Errno::EPIPE
    # The above invocation via `Utils.popen` can fail, causing the pipe to be
    # prematurely closed (before we can write to it) and thus resulting in a
    # broken pipe error. The root cause is usually a missing or malfunctioning
    # `git-credential-osxkeychain` helper.
    ""
  end

  def api_credentials_type
    token, username = api_credentials
    if token && !token.empty?
      if username && !username.empty?
        :keychain
      else
        :environment
      end
    else
      :none
    end
  end

  def api_credentials_error_message(response_headers, needed_scopes)
    return if response_headers.empty?

    @api_credentials_error_message_printed ||= begin
      unauthorized = (response_headers["http/1.1"] == "401 Unauthorized")
      scopes = response_headers["x-accepted-oauth-scopes"].to_s.split(", ")
      needed_human_scopes = needed_scopes.join(", ")
      needed_human_scopes = "none" if needed_human_scopes.empty?
      if !unauthorized && scopes.empty?
        credentials_scopes = response_headers["x-oauth-scopes"]

        case GitHub.api_credentials_type
        when :keychain
          onoe <<-EOS.undent
            Your macOS keychain GitHub credentials do not have sufficient scope!
            Scopes they need: #{needed_human_scopes}
            Scopes they have: #{credentials_scopes}
            Create a personal access token: #{ALL_SCOPES_URL}
            and then set HOMEBREW_GITHUB_API_TOKEN as the authentication method instead.
          EOS
        when :environment
          onoe <<-EOS.undent
            Your HOMEBREW_GITHUB_API_TOKEN does not have sufficient scope!
            Scopes they need: #{needed_human_scopes}
            Scopes it has: #{credentials_scopes}
            Create a new personal access token: #{ALL_SCOPES_URL}
            and then set the new HOMEBREW_GITHUB_API_TOKEN as the authentication method instead.
          EOS
        end
      end
      true
    end
  end

  def open(url, data: nil, scopes: [].freeze)
    # This is a no-op if the user is opting out of using the GitHub API.
    return if ENV["HOMEBREW_NO_GITHUB_API"]

    args = %W[--header application/vnd.github.v3+json --write-out \n%{http_code}]
    args += curl_args

    token, username = api_credentials
    case api_credentials_type
    when :keychain
      args += %W[--user #{username}:#{token}]
    when :environment
      args += ["--header", "Authorization: token #{token}"]
    end

    data_tmpfile = nil
    if data
      begin
        data = Utils::JSON.dump data
        data_tmpfile = Tempfile.new("github_api_post", HOMEBREW_TEMP)
      rescue Utils::JSON::Error => e
        raise Error, "Failed to parse JSON request:\n#{e.message}\n#{data}", e.backtrace
      end
    end

    headers_tmpfile = Tempfile.new("github_api_headers", HOMEBREW_TEMP)
    begin
      if data
        data_tmpfile.write data
        data_tmpfile.close
        args += ["--data", "@#{data_tmpfile.path}"]
      end

      args += ["--dump-header", headers_tmpfile.path.to_s]

      output, errors, status = curl_output(url.to_s, *args)
      output, _, http_code = output.rpartition("\n")
      output, _, http_code = output.rpartition("\n") if http_code == "000"
      headers = headers_tmpfile.read
    ensure
      if data_tmpfile
        data_tmpfile.close
        data_tmpfile.unlink
      end
      headers_tmpfile.close
      headers_tmpfile.unlink
    end

    begin
      if !http_code.start_with?("2") && !status.success?
        raise_api_error(output, errors, http_code, headers, scopes)
      end
      json = Utils::JSON.load output
      if block_given?
        yield json
      else
        json
      end
    rescue Utils::JSON::Error => e
      raise Error, "Failed to parse JSON response\n#{e.message}", e.backtrace
    end
  end

  def raise_api_error(output, errors, http_code, headers, scopes)
    meta = {}
    headers.lines.each do |l|
      key, _, value = l.delete(":").partition(" ")
      key = key.downcase.strip
      next if key.empty?
      meta[key] = value.strip
    end

    if meta.fetch("x-ratelimit-remaining", 1).to_i <= 0
      reset = meta.fetch("x-ratelimit-reset").to_i
      error = Utils::JSON.load(output)["message"]
      raise RateLimitExceededError.new(reset, error)
    end

    GitHub.api_credentials_error_message(meta, scopes)

    case http_code
    when "401", "403"
      raise AuthenticationFailedError, output
    when "404"
      raise HTTPNotFoundError, output
    else
      error = begin
        Utils::JSON.load(output)["message"]
      rescue
        nil
      end
      error ||= "curl failed! #{errors}"
      raise Error, error
    end
  end

  def issues_matching(query, qualifiers = {})
    uri = ISSUES_URI.dup
    uri.query = build_query_string(query, qualifiers)
    open(uri) { |json| json["items"] }
  end

  def repository(user, repo)
    open(URI.parse("https://api.github.com/repos/#{user}/#{repo}")) { |j| j }
  end

  def build_query_string(query, qualifiers)
    s = "q=#{uri_escape(query)}+"
    s << build_search_qualifier_string(qualifiers)
    s << "&per_page=100"
  end

  def build_search_qualifier_string(qualifiers)
    {
      repo: "Homebrew/homebrew-core",
      in: "title",
    }.update(qualifiers).map do |qualifier, value|
      "#{qualifier}:#{value}"
    end.join("+")
  end

  def uri_escape(query)
    if URI.respond_to?(:encode_www_form_component)
      URI.encode_www_form_component(query)
    else
      require "erb"
      ERB::Util.url_encode(query)
    end
  end

  def issues_for_formula(name, options = {})
    tap = options[:tap] || CoreTap.instance
    issues_matching(name, state: "open", repo: "#{tap.user}/homebrew-#{tap.repo}")
  end

  def print_pull_requests_matching(query)
    return [] if ENV["HOMEBREW_NO_GITHUB_API"]
    ohai "Searching pull requests..."

    open_or_closed_prs = issues_matching(query, type: "pr")

    open_prs = open_or_closed_prs.select { |i| i["state"] == "open" }
    if !open_prs.empty?
      puts "Open pull requests:"
      prs = open_prs
    elsif !open_or_closed_prs.empty?
      puts "Closed pull requests:"
      prs = open_or_closed_prs
    else
      return
    end

    prs.each { |i| puts "#{i["title"]} (#{i["html_url"]})" }
  end

  def private_repo?(user, repo)
    uri = URI.parse("https://api.github.com/repos/#{user}/#{repo}")
    open(uri) { |json| json["private"] }
  end
end
