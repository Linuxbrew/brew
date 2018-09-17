require "uri"
require "tempfile"

module GitHub
  module_function

  API_URL = "https://api.github.com".freeze

  CREATE_GIST_SCOPES = ["gist"].freeze
  CREATE_ISSUE_FORK_OR_PR_SCOPES = ["public_repo"].freeze
  ALL_SCOPES = (CREATE_GIST_SCOPES + CREATE_ISSUE_FORK_OR_PR_SCOPES).freeze
  ALL_SCOPES_URL = Formatter.url(
    "https://github.com/settings/tokens/new?scopes=#{ALL_SCOPES.join(",")}&description=Homebrew",
  ).freeze
  PR_ENV_KEY = "HOMEBREW_NEW_FORMULA_PULL_REQUEST_URL".freeze
  PR_ENV = ENV[PR_ENV_KEY]

  Error = Class.new(RuntimeError)
  HTTPNotFoundError = Class.new(Error)

  class RateLimitExceededError < Error
    def initialize(reset, error)
      super <<~EOS
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
        message << <<~EOS
          HOMEBREW_GITHUB_API_TOKEN may be invalid or expired; check:
          #{Formatter.url("https://github.com/settings/tokens")}
        EOS
      else
        message << <<~EOS
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
    return :none if !token || token.empty?
    return :environment if !username || username.empty?

    :keychain
  end

  def api_credentials_error_message(response_headers, needed_scopes)
    return if response_headers.empty?

    @api_credentials_error_message ||= begin
      unauthorized = (response_headers["http/1.1"] == "401 Unauthorized")
      scopes = response_headers["x-accepted-oauth-scopes"].to_s.split(", ")
      needed_human_scopes = needed_scopes.join(", ")
      needed_human_scopes = "none" if needed_human_scopes.empty?
      if !unauthorized && scopes.empty?
        credentials_scopes = response_headers["x-oauth-scopes"]

        case GitHub.api_credentials_type
        when :keychain
          onoe <<~EOS
            Your macOS keychain GitHub credentials do not have sufficient scope!
            Scopes they need: #{needed_human_scopes}
            Scopes they have: #{credentials_scopes}
            Create a personal access token: #{ALL_SCOPES_URL}
            and then set HOMEBREW_GITHUB_API_TOKEN as the authentication method instead.
          EOS
        when :environment
          onoe <<~EOS
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

  def open_api(url, data: nil, scopes: [].freeze)
    # This is a no-op if the user is opting out of using the GitHub API.
    return block_given? ? yield({}) : {} if ENV["HOMEBREW_NO_GITHUB_API"]

    args = ["--header", "application/vnd.github.v3+json", "--write-out", "\n%{http_code}"]

    token, username = api_credentials
    case api_credentials_type
    when :keychain
      args += ["--user", "#{username}:#{token}"]
    when :environment
      args += ["--header", "Authorization: token #{token}"]
    end

    data_tmpfile = nil
    if data
      begin
        data = JSON.generate data
        data_tmpfile = Tempfile.new("github_api_post", HOMEBREW_TEMP)
      rescue JSON::ParserError => e
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

      args += ["--dump-header", headers_tmpfile.path]

      output, errors, status = curl_output("--location", url.to_s, *args)
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
      if !http_code.start_with?("2") || !status.success?
        raise_api_error(output, errors, http_code, headers, scopes)
      end
      json = JSON.parse output
      if block_given?
        yield json
      else
        json
      end
    rescue JSON::ParserError => e
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
      error = JSON.parse(output)["message"]
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
        JSON.parse(output)["message"]
      rescue
        nil
      end
      error ||= "curl failed! #{errors}"
      raise Error, error
    end
  end

  def search_issues(query, **qualifiers)
    search("issues", query, **qualifiers)
  end

  def repository(user, repo)
    open_api(url_to("repos", user, repo))
  end

  def search_code(**qualifiers)
    search("code", **qualifiers)
  end

  def issues_for_formula(name, options = {})
    tap = options[:tap] || CoreTap.instance
    search_issues(name, state: "open", repo: "#{tap.user}/homebrew-#{tap.repo}", in: "title")
  end

  def print_pull_requests_matching(query)
    open_or_closed_prs = search_issues(query, type: "pr", user: "Homebrew")

    open_prs = open_or_closed_prs.select { |i| i["state"] == "open" }
    prs = if !open_prs.empty?
      puts "Open pull requests:"
      open_prs
    else
      puts "Closed pull requests:" unless open_or_closed_prs.empty?
      open_or_closed_prs
    end

    prs.each { |i| puts "#{i["title"]} (#{i["html_url"]})" }
  end

  def create_fork(repo)
    url = "#{API_URL}/repos/#{repo}/forks"
    data = {}
    scopes = CREATE_ISSUE_FORK_OR_PR_SCOPES
    open_api(url, data: data, scopes: scopes)
  end

  def create_pull_request(repo, title, head, base, body)
    url = "#{API_URL}/repos/#{repo}/pulls"
    data = { title: title, head: head, base: base, body: body }
    scopes = CREATE_ISSUE_FORK_OR_PR_SCOPES
    open_api(url, data: data, scopes: scopes)
  end

  def private_repo?(full_name)
    uri = url_to "repos", full_name
    open_api(uri) { |json| json["private"] }
  end

  def query_string(*main_params, **qualifiers)
    params = main_params

    params += qualifiers.flat_map do |key, value|
      Array(value).map { |v| "#{key}:#{v}" }
    end

    "q=#{URI.encode_www_form_component(params.join(" "))}&per_page=100"
  end

  def url_to(*subroutes)
    URI.parse([API_URL, *subroutes].join("/"))
  end

  def search(entity, *queries, **qualifiers)
    uri = url_to "search", entity
    uri.query = query_string(*queries, **qualifiers)
    open_api(uri) { |json| json.fetch("items", []) }
  end

  def create_issue_comment(body)
    return false unless PR_ENV

    _, user, repo, pr = *PR_ENV.match(HOMEBREW_PULL_OR_COMMIT_URL_REGEX)
    if !user || !repo || !pr
      opoo <<-EOS.undent
        #{PR_ENV_KEY} set but regex matched:
        user: #{user.inspect}, repo: #{repo.inspect}, pr: #{pr.inspect}
      EOS
      return false
    end

    url = "#{API_URL}/repos/#{user}/#{repo}/issues/#{pr}/comments"
    data = { "body" => body }
    if issue_comment_exists?(user, repo, pr, body)
      ohai "Skipping: identical comment exists on #{PR_ENV}"
      return true
    end

    scopes = CREATE_ISSUE_FORK_OR_PR_SCOPES
    open_api(url, data: data, scopes: scopes)
  end

  def issue_comment_exists?(user, repo, pr, body)
    url = "#{API_URL}/repos/#{user}/#{repo}/issues/#{pr}/comments"
    comments = open_api(url)
    return unless comments

    comments.any? { |comment| comment["body"].eql?(body) }
  end

  def api_errors
    [GitHub::AuthenticationFailedError, GitHub::HTTPNotFoundError,
     GitHub::RateLimitExceededError, GitHub::Error, JSON::ParserError].freeze
  end
end
