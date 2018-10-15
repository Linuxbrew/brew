require "download_strategy"

# S3DownloadStrategy downloads tarballs from AWS S3.
# To use it, add `:using => :s3` to the URL section of your
# formula.  This download strategy uses AWS access tokens (in the
# environment variables `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`)
# to sign the request.  This strategy is good in a corporate setting,
# because it lets you use a private S3 bucket as a repo for internal
# distribution.  (It will work for public buckets as well.)
class S3DownloadStrategy < CurlDownloadStrategy
  def initialize(url, name, version, **meta)
    odeprecated("S3DownloadStrategy",
      "maintaining S3DownloadStrategy in your own formula or tap")
    super
  end

  def _fetch(url:, resolved_url:)
    if url !~ %r{^https?://([^.].*)\.s3\.amazonaws\.com/(.+)$} &&
       url !~ %r{^s3://([^.].*?)/(.+)$}
      raise "Bad S3 URL: " + url
    end

    bucket = Regexp.last_match(1)
    key = Regexp.last_match(2)

    ENV["AWS_ACCESS_KEY_ID"] = ENV["HOMEBREW_AWS_ACCESS_KEY_ID"]
    ENV["AWS_SECRET_ACCESS_KEY"] = ENV["HOMEBREW_AWS_SECRET_ACCESS_KEY"]

    begin
      signer = Aws::S3::Presigner.new
      s3url = signer.presigned_url :get_object, bucket: bucket, key: key
    rescue Aws::Sigv4::Errors::MissingCredentialsError
      ohai "AWS credentials missing, trying public URL instead."
      s3url = url
    end

    curl_download s3url, to: temporary_path
  end
end

# GitHubPrivateRepositoryDownloadStrategy downloads contents from GitHub
# Private Repository. To use it, add
# `:using => :github_private_repo` to the URL section of
# your formula. This download strategy uses GitHub access tokens (in the
# environment variables `HOMEBREW_GITHUB_API_TOKEN`) to sign the request.  This
# strategy is suitable for corporate use just like S3DownloadStrategy, because
# it lets you use a private GitHub repository for internal distribution.  It
# works with public one, but in that case simply use CurlDownloadStrategy.
class GitHubPrivateRepositoryDownloadStrategy < CurlDownloadStrategy
  require "utils/formatter"
  require "utils/github"

  def initialize(url, name, version, **meta)
    odeprecated("GitHubPrivateRepositoryDownloadStrategy",
      "maintaining GitHubPrivateRepositoryDownloadStrategy in your own formula or tap")
    super
    parse_url_pattern
    set_github_token
  end

  def parse_url_pattern
    unless match = url.match(%r{https://github.com/([^/]+)/([^/]+)/(\S+)})
      raise CurlDownloadStrategyError, "Invalid url pattern for GitHub Repository."
    end

    _, @owner, @repo, @filepath = *match
  end

  def download_url
    "https://#{@github_token}@github.com/#{@owner}/#{@repo}/#{@filepath}"
  end

  private

  def _fetch(url:, resolved_url:)
    curl_download download_url, to: temporary_path
  end

  def set_github_token
    @github_token = ENV["HOMEBREW_GITHUB_API_TOKEN"]
    unless @github_token
      raise CurlDownloadStrategyError, "Environmental variable HOMEBREW_GITHUB_API_TOKEN is required."
    end

    validate_github_repository_access!
  end

  def validate_github_repository_access!
    # Test access to the repository
    GitHub.repository(@owner, @repo)
  rescue GitHub::HTTPNotFoundError
    # We only handle HTTPNotFoundError here,
    # becase AuthenticationFailedError is handled within util/github.
    message = <<~EOS
      HOMEBREW_GITHUB_API_TOKEN can not access the repository: #{@owner}/#{@repo}
      This token may not have permission to access the repository or the url of formula may be incorrect.
    EOS
    raise CurlDownloadStrategyError, message
  end
end

# GitHubPrivateRepositoryReleaseDownloadStrategy downloads tarballs from GitHub
# Release assets. To use it, add `:using => :github_private_release` to the URL section
# of your formula. This download strategy uses GitHub access tokens (in the
# environment variables HOMEBREW_GITHUB_API_TOKEN) to sign the request.
class GitHubPrivateRepositoryReleaseDownloadStrategy < GitHubPrivateRepositoryDownloadStrategy
  def initialize(url, name, version, **meta)
    odeprecated("GitHubPrivateRepositoryReleaseDownloadStrategy",
      "maintaining GitHubPrivateRepositoryReleaseDownloadStrategy in your own formula or tap")
    super
  end

  def parse_url_pattern
    url_pattern = %r{https://github.com/([^/]+)/([^/]+)/releases/download/([^/]+)/(\S+)}
    unless @url =~ url_pattern
      raise CurlDownloadStrategyError, "Invalid url pattern for GitHub Release."
    end

    _, @owner, @repo, @tag, @filename = *@url.match(url_pattern)
  end

  def download_url
    "https://#{@github_token}@api.github.com/repos/#{@owner}/#{@repo}/releases/assets/#{asset_id}"
  end

  private

  def _fetch(url:, resolved_url:)
    # HTTP request header `Accept: application/octet-stream` is required.
    # Without this, the GitHub API will respond with metadata, not binary.
    curl_download download_url, "--header", "Accept: application/octet-stream", to: temporary_path
  end

  def asset_id
    @asset_id ||= resolve_asset_id
  end

  def resolve_asset_id
    release_metadata = fetch_release_metadata
    assets = release_metadata["assets"].select { |a| a["name"] == @filename }
    raise CurlDownloadStrategyError, "Asset file not found." if assets.empty?

    assets.first["id"]
  end

  def fetch_release_metadata
    release_url = "https://api.github.com/repos/#{@owner}/#{@repo}/releases/tags/#{@tag}"
    GitHub.open_api(release_url)
  end
end

# ScpDownloadStrategy downloads files using ssh via scp. To use it, add
# `:using => :scp` to the URL section of your formula or
# provide a URL starting with scp://. This strategy uses ssh credentials for
# authentication. If a public/private keypair is configured, it will not
# prompt for a password.
#
# @example
#   class Abc < Formula
#     url "scp://example.com/src/abc.1.0.tar.gz"
#     ...
class ScpDownloadStrategy < AbstractFileDownloadStrategy
  def initialize(url, name, version, **meta)
    odeprecated("ScpDownloadStrategy",
      "maintaining ScpDownloadStrategy in your own formula or tap")
    super
    parse_url_pattern
  end

  def parse_url_pattern
    url_pattern = %r{scp://([^@]+@)?([^@:/]+)(:\d+)?/(\S+)}
    if @url !~ url_pattern
      raise ScpDownloadStrategyError, "Invalid URL for scp: #{@url}"
    end

    _, @user, @host, @port, @path = *@url.match(url_pattern)
  end

  def fetch
    ohai "Downloading #{@url}"

    if cached_location.exist?
      puts "Already downloaded: #{cached_location}"
    else
      system_command! "scp", args: [scp_source, temporary_path.to_s]
      ignore_interrupts { temporary_path.rename(cached_location) }
    end
  end

  def clear_cache
    super
    rm_rf(temporary_path)
  end

  private

  def scp_source
    path_prefix = "/" unless @path.start_with?("~")
    port_arg = "-P #{@port[1..-1]} " if @port
    "#{port_arg}#{@user}#{@host}:#{path_prefix}#{@path}"
  end
end

class DownloadStrategyDetector
  class << self
    module Compat
      def detect(url, using = nil)
        strategy = super
        require_aws_sdk if strategy == S3DownloadStrategy
        strategy
      end

      def detect_from_url(url)
        case url
        when %r{^s3://}
          odeprecated("s3://",
            "maintaining S3DownloadStrategy in your own formula or tap")
          S3DownloadStrategy
        when %r{^scp://}
          odeprecated("scp://",
            "maintaining ScpDownloadStrategy in your own formula or tap")
          ScpDownloadStrategy
        else
          super(url)
        end
      end

      def detect_from_symbol(symbol)
        case symbol
        when :github_private_repo
          odeprecated(":github_private_repo",
            "maintaining GitHubPrivateRepositoryDownloadStrategy in your own formula or tap")
          GitHubPrivateRepositoryDownloadStrategy
        when :github_private_release
          odeprecated(":github_private_repo",
            "maintaining GitHubPrivateRepositoryReleaseDownloadStrategy in your own formula or tap")
          GitHubPrivateRepositoryReleaseDownloadStrategy
        when :s3
          odeprecated(":s3",
            "maintaining S3DownloadStrategy in your own formula or tap")
          S3DownloadStrategy
        when :scp
          odeprecated(":scp",
            "maintaining ScpDownloadStrategy in your own formula or tap")
          ScpDownloadStrategy
        else
          super(symbol)
        end
      end
    end

    prepend Compat
  end
end
