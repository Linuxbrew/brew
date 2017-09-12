require "cgi"

# We abuse Homebrew's download strategies considerably here.
# * Our downloader instances only invoke the fetch and
#   clear_cache methods, ignoring stage
# * Our overridden fetch methods are expected to return
#   a value: the successfully downloaded file.

module Hbc
  class AbstractDownloadStrategy
    attr_reader :cask, :name, :url, :uri_object, :version

    def initialize(cask, command: SystemCommand)
      @cask       = cask
      @command    = command
      # TODO: this excess of attributes is a function of integrating
      #       with Homebrew's classes. Later we should be able to remove
      #       these in favor of @cask
      @name       = cask.token
      @url        = cask.url.to_s
      @uri_object = cask.url
      @version    = cask.version
    end

    # All download strategies are expected to implement these methods
    def fetch; end

    def cached_location; end

    def clear_cache; end
  end

  class HbVCSDownloadStrategy < AbstractDownloadStrategy
    REF_TYPES = [:branch, :revision, :revisions, :tag].freeze

    def initialize(*args, **options)
      super(*args, **options)
      @ref_type, @ref = extract_ref
      @clone = Hbc.cache.join(cache_filename)
    end

    def extract_ref
      key = REF_TYPES.find do |type|
        uri_object.respond_to?(type) && uri_object.send(type)
      end
      [key, key ? uri_object.send(key) : nil]
    end

    def cache_filename
      "#{name}--#{cache_tag}"
    end

    def cache_tag
      "__UNKNOWN__"
    end

    def cached_location
      @clone
    end

    def clear_cache
      cached_location.rmtree if cached_location.exist?
    end
  end

  class CurlDownloadStrategy < AbstractDownloadStrategy
    def tarball_path
      @tarball_path ||= Hbc.cache.join("#{name}--#{version}#{ext}")
    end

    def temporary_path
      @temporary_path ||= tarball_path.sub(/$/, ".incomplete")
    end

    def cached_location
      tarball_path
    end

    def clear_cache
      [cached_location, temporary_path].each do |path|
        next unless path.exist?

        begin
          LockFile.new(path.basename).with_lock do
            path.unlink
          end
        rescue OperationInProgressError
          raise CurlDownloadStrategyError, "#{path} is in use by another process"
        end
      end
    end

    def _fetch
      curl_download url, *cask_curl_args, to: temporary_path, user_agent: uri_object.user_agent
    end

    def fetch
      ohai "Downloading #{@url}"
      if tarball_path.exist?
        puts "Already downloaded: #{tarball_path}"
      else
        had_incomplete_download = temporary_path.exist?
        begin
          LockFile.new(temporary_path.basename).with_lock do
            _fetch
          end
        rescue ErrorDuringExecution
          # 33 == range not supported
          # try wiping the incomplete download and retrying once
          if $CHILD_STATUS.exitstatus == 33 && had_incomplete_download
            ohai "Trying a full download"
            temporary_path.unlink
            had_incomplete_download = false
            retry
          end

          msg = @url
          msg.concat("\nThe incomplete download is cached at #{temporary_path}") if temporary_path.exist?
          raise CurlDownloadStrategyError, msg
        end
        ignore_interrupts { temporary_path.rename(tarball_path) }
      end
      tarball_path
    end

    private

    def cask_curl_args
      cookies_args + referer_args
    end

    def cookies_args
      if uri_object.cookies
        [
          "-b",
          # sort_by is for predictability between Ruby versions
          uri_object
            .cookies
            .sort_by(&:to_s)
            .map { |key, value| "#{CGI.escape(key.to_s)}=#{CGI.escape(value.to_s)}" }
            .join(";"),
        ]
      else
        []
      end
    end

    def referer_args
      if uri_object.referer
        ["-e", uri_object.referer]
      else
        []
      end
    end

    def ext
      Pathname.new(@url).extname[/[^?]+/]
    end
  end

  class CurlPostDownloadStrategy < CurlDownloadStrategy
    def cask_curl_args
      super.concat(post_args)
    end

    def post_args
      if uri_object.data
        # sort_by is for predictability between Ruby versions
        uri_object
          .data
          .sort_by(&:to_s)
          .map { |key, value| ["-d", "#{CGI.escape(key.to_s)}=#{CGI.escape(value.to_s)}"] }
          .flatten
      else
        ["-X", "POST"]
      end
    end
  end

  class SubversionDownloadStrategy < HbVCSDownloadStrategy
    def cache_tag
      # TODO: pass versions as symbols, support :head here
      (version == "head") ? "svn-HEAD" : "svn"
    end

    def repo_valid?
      (@clone/".svn").directory?
    end

    def repo_url
      `svn info '#{@clone}' 2>/dev/null`.strip[/^URL: (.+)$/, 1]
    end

    # super does not provide checks for already-existing downloads
    def fetch
      if cached_location.directory?
        puts "Already downloaded: #{cached_location}"
      else
        @url = @url.sub(/^svn\+/, "") if @url =~ %r{^svn\+http://}
        ohai "Checking out #{@url}"

        clear_cache unless @url.chomp("/") == repo_url || quiet_system("svn", "switch", @url, @clone)

        if @clone.exist? && !repo_valid?
          puts "Removing invalid SVN repo from cache"
          clear_cache
        end

        case @ref_type
        when :revision
          fetch_repo @clone, @url, @ref
        when :revisions
          # nil is OK for main_revision, as fetch_repo will then get latest
          main_revision = @ref[:trunk]
          fetch_repo @clone, @url, main_revision, true

          fetch_externals do |external_name, external_url|
            fetch_repo @clone + external_name, external_url, @ref[external_name], true
          end
        else
          fetch_repo @clone, @url
        end
      end
      cached_location
    end

    # This primary reason for redefining this method is the trust_cert
    # option, controllable from the Cask definition. We also force
    # consistent timestamps.  The rest of this method is similar to
    # Homebrew's, but translated to local idiom.
    def fetch_repo(target, url, revision = uri_object.revision, ignore_externals = false)
      # Use "svn up" when the repository already exists locally.
      # This saves on bandwidth and will have a similar effect to verifying the
      # cache as it will make any changes to get the right revision.
      svncommand = target.directory? ? "up" : "checkout"
      args = [svncommand]

      # SVN shipped with XCode 3.1.4 can't force a checkout.
      args << "--force" unless MacOS.version == :leopard

      # make timestamps consistent for checksumming
      args.concat(%w[--config-option config:miscellany:use-commit-times=yes])

      if uri_object.trust_cert
        args << "--trust-server-cert"
        args << "--non-interactive"
      end

      args << url unless target.directory?
      args << target
      args << "-r" << revision if revision
      args << "--ignore-externals" if ignore_externals
      @command.run!("/usr/bin/svn",
                    args:         args,
                    print_stderr: false)
    end

    def shell_quote(str)
      # Oh god escaping shell args.
      # See http://notetoself.vrensk.com/2008/08/escaping-single-quotes-in-ruby-harder-than-expected/
      str.gsub(/\\|'/) { |c| "\\#{c}" }
    end

    def fetch_externals
      `svn propget svn:externals '#{shell_quote(@url)}'`.chomp.each_line do |line|
        name, url = line.split(/\s+/)
        yield name, url
      end
    end
  end
end
