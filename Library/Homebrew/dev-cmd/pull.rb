#:  * `pull` [`--bottle`] [`--bump`] [`--clean`] [`--ignore-whitespace`] [`--resolve`] [`--branch-okay`] [`--no-pbcopy`] [`--no-publish`] [`--warn-on-publish-failure`] [`--bintray-org=`<bintray-org>] [`--test-bot-user=`<test-bot-user>] <patch-source> [<patch-source>]:
#:    Get a patch from a GitHub commit or pull request and apply it to Homebrew.
#:    Optionally, publish updated bottles for the formulae changed by the patch.
#:
#:    Each <patch-source> may be one of:
#:
#:      ~ The ID number of a PR (pull request) in the homebrew/core GitHub
#:        repository
#:
#:      ~ The URL of a PR on GitHub, using either the web page or API URL
#:        formats. In this form, the PR may be on Homebrew/brew,
#:        Homebrew/homebrew-core or any tap.
#:
#:      ~ The URL of a commit on GitHub
#:
#:      ~ A "https://jenkins.brew.sh/job/..." string specifying a testing job ID
#:
#:    If `--bottle` is passed, handle bottles, pulling the bottle-update
#:    commit and publishing files on Bintray.
#:
#:    If `--bump` is passed, for one-formula PRs, automatically reword
#:    commit message to our preferred format.
#:
#:    If `--clean` is passed, do not rewrite or otherwise modify the
#:    commits found in the pulled PR.
#:
#:    If `--ignore-whitespace` is passed, silently ignore whitespace
#:    discrepancies when applying diffs.
#:
#:    If `--resolve` is passed, when a patch fails to apply, leave in
#:    progress and allow user to resolve, instead of aborting.
#:
#:    If `--branch-okay` is passed, do not warn if pulling to a branch
#:    besides master (useful for testing).
#:
#:    If `--no-pbcopy` is passed, do not copy anything to the system
#:    clipboard.
#:
#:    If `--no-publish` is passed, do not publish bottles to Bintray.
#:
#:    If `--warn-on-publish-failure` was passed, do not exit if there's a
#:    failure publishing bottles on Bintray.
#:
#:    If `--bintray-org=`<bintray-org> is passed, publish at the provided Bintray
#:    organisation.
#:
#:    If `--test-bot-user=`<test-bot-user> is passed, pull the bottle block
#:    commit from the provided user on GitHub.

require "net/http"
require "net/https"
require "json"
require "cli_parser"
require "formula"
require "formulary"
require "version"
require "pkg_version"

module GitHub
  module_function

  # Return the corresponding test-bot user name for the given GitHub organization.
  def test_bot_user(user, test_bot)
    return test_bot if test_bot
    return "BrewTestBot" if user.casecmp("homebrew").zero?

    "#{user.capitalize}TestBot"
  end
end

module Homebrew
  module_function

  def pull_args
    Homebrew::CLI::Parser.new do
      usage_banner <<~EOS
        `pull` [<options>] <patch sources>

        Get a patch from a GitHub commit or pull request and apply it to Homebrew.
        Optionally, publish updated bottles for the formulae changed by the patch.

        Each <patch source> may be one of:

          ~ The ID number of a PR (pull request) in the homebrew/core GitHub
            repository

          ~ The URL of a PR on GitHub, using either the web page or API URL
            formats. In this form, the PR may be on Homebrew/brew,
            Homebrew/homebrew-core or any tap.

          ~ The URL of a commit on GitHub

          ~ A "https://jenkins.brew.sh/job/..." string specifying a testing job ID
      EOS
      switch "--bottle",
        description: "Handle bottles, pulling the bottle-update commit and publishing files on Bintray."
      switch "--bump",
        description: "For one-formula PRs, automatically reword commit message to our preferred format."
      switch "--clean",
        description: "Do not rewrite or otherwise modify the commits found in the pulled PR."
      switch "--ignore-whitespace",
        description: "Silently ignore whitespace discrepancies when applying diffs."
      switch "--resolve",
        description: "When a patch fails to apply, leave in progress and allow user to resolve, instead "\
                     "of aborting."
      switch "--branch-okay",
        description: "Do not warn if pulling to a branch besides master (useful for testing)."
      switch "--no-pbcopy",
        description: "Do not copy anything to the system clipboard."
      switch "--no-publish",
        description: "Do not publish bottles to Bintray."
      switch "--warn-on-publish-failure",
        description: "Do not exit if there's a failure publishing bottles on Bintray."
      flag   "--bintray-org=",
        description: "Publish bottles at the provided Bintray <organisation>."
      flag   "--test-bot-user=",
        description: "Pull the bottle block commit from the provided <user> on GitHub."
      flag   "--tap=",
        description: "Apply the PR to the specified tap."
      switch :verbose
      switch :debug
    end
  end

  def pull
    odie "You meant `git pull --rebase`." if ARGV[0] == "--rebase"

    pull_args.parse

    if ARGV.named.empty?
      odie "This command requires at least one argument containing a URL or pull request number"
    end

    # Passthrough Git environment variables for e.g. git am
    if ENV["HOMEBREW_GIT_NAME"]
      ENV["GIT_COMMITTER_NAME"] = ENV["HOMEBREW_GIT_NAME"]
    end
    if ENV["HOMEBREW_GIT_EMAIL"]
      ENV["GIT_COMMITTER_EMAIL"] = ENV["HOMEBREW_GIT_EMAIL"]
    end

    # Depending on user configuration, git may try to invoke gpg.
    if Utils.popen_read("git config --get --bool commit.gpgsign").chomp == "true"
      begin
        gnupg = Formula["gnupg"]
      rescue FormulaUnavailableError # rubocop:disable Lint/HandleExceptions
      else
        if gnupg.installed?
          path = PATH.new(ENV.fetch("PATH"))
          path.prepend(gnupg.installed_prefix/"bin")
          ENV["PATH"] = path
        end
      end
    end

    do_bump = args.bump? && !args.clean?

    # Formulae with affected bottles that were published
    bintray_published_formulae = []
    tap = nil

    ARGV.named.each do |arg|
      arg = "#{CoreTap.instance.default_remote}/pull/#{arg}" if arg.to_i.positive?
      if (testing_match = arg.match %r{/job/Homebrew.*Testing/(\d+)/})
        tap = @args[:tap]
        tap = if tap&.start_with?("homebrew/")
          Tap.fetch("homebrew", tap.delete_prefix("homebrew/"))
        elsif tap
          odie "Tap option did not start with \"homebrew/\": #{tap}"
        else
          CoreTap.instance
        end
        _, testing_job = *testing_match
        url = "https://github.com/Homebrew/homebrew-#{tap.repo}/compare/master...BrewTestBot:testing-#{testing_job}"
        odie "Testing URLs require `--bottle`!" unless args.bottle?
      elsif (api_match = arg.match HOMEBREW_PULL_API_REGEX)
        _, user, repo, issue = *api_match
        url = "https://github.com/#{user}/#{repo}/pull/#{issue}"
        tap = Tap.fetch(user, repo) if repo.start_with?("homebrew-")
      elsif (url_match = arg.match HOMEBREW_PULL_OR_COMMIT_URL_REGEX)
        url, user, repo, issue = *url_match
        tap = Tap.fetch(user, repo) if repo.start_with?("homebrew-")
      else
        odie "Not a GitHub pull request or commit: #{arg}"
      end

      if !testing_job && args.bottle? && issue.nil?
        odie "No pull request detected!"
      end

      tap = Tap.fetch(ARGV.value("tap")) if ARGV.value("tap")
      if tap
        tap.install unless tap.installed?
        Dir.chdir tap.path
      else
        Dir.chdir HOMEBREW_REPOSITORY
      end

      # The cache directory seems like a good place to put patches.
      HOMEBREW_CACHE.mkpath

      # Store current revision and branch
      orig_revision = `git rev-parse --short HEAD`.strip
      branch = `git symbolic-ref --short HEAD`.strip

      unless branch == "master" || args.clean? || args.branch_okay?
        opoo "Current branch is #{branch}: do you need to pull inside master?"
      end

      patch_puller = PatchPuller.new(url, args)
      patch_puller.fetch_patch
      patch_changes = files_changed_in_patch(patch_puller.patchpath, tap)

      is_bumpable = patch_changes[:formulae].length == 1 && patch_changes[:others].empty?
      if do_bump
        odie "No changed formulae found to bump" if patch_changes[:formulae].empty?
        if patch_changes[:formulae].length > 1
          odie "Can only bump one changed formula; bumped #{patch_changes[:formulae]}"
        end
        odie "Can not bump if non-formula files are changed" unless patch_changes[:others].empty?
      end
      if is_bumpable
        old_versions = current_versions_from_info_external(patch_changes[:formulae].first)
      end
      patch_puller.apply_patch

      changed_formulae_names = []

      if tap
        Utils.popen_read(
          "git", "diff-tree", "-r", "--name-only",
          "--diff-filter=AM", orig_revision, "HEAD", "--", tap.formula_dir.to_s
        ).each_line do |line|
          next unless line.end_with? ".rb\n"

          name = "#{tap.name}/#{File.basename(line.chomp, ".rb")}"
          changed_formulae_names << name
        end
      end

      fetch_bottles = false
      changed_formulae_names.each do |name|
        next if ENV["HOMEBREW_DISABLE_LOAD_FORMULA"]

        begin
          f = Formula[name]
        rescue Exception # rubocop:disable Lint/RescueException
          # Make sure we catch syntax errors.
          next
        end

        if f.stable
          stable_urls = [f.stable.url] + f.stable.mirrors
          stable_urls.grep(%r{^https://dl.bintray.com/homebrew/mirror/}) do |mirror_url|
            check_bintray_mirror(f.full_name, mirror_url)
          end
        end

        if args.bottle?
          if f.bottle_unneeded?
            ohai "#{f}: skipping unneeded bottle."
          elsif f.bottle_disabled?
            ohai "#{f}: skipping disabled bottle: #{f.bottle_disable_reason}"
          else
            fetch_bottles = true
          end
        else
          next unless f.bottle_defined?

          opoo "#{f.full_name} has a bottle: do you need to update it with --bottle?"
        end
      end

      orig_message = message = `git log HEAD^.. --format=%B`
      slug = if (url_match = url.match HOMEBREW_PULL_OR_COMMIT_URL_REGEX)
        _, user, repo = *url_match
        "#{user}/#{repo}"
      end
      if issue && !args.clean?
        ohai "Patch closes issue ##{issue}"
        close_message = "Closes #{slug}##{issue}."
        # If this is a pull request, append a close message.
        message += "\n#{close_message}" unless message.include? close_message
      end

      if changed_formulae_names.empty?
        odie "cannot bump: no changed formulae found after applying patch" if do_bump
        is_bumpable = false
      end

      is_bumpable = false if args.clean?
      is_bumpable = false if ENV["HOMEBREW_DISABLE_LOAD_FORMULA"]

      if is_bumpable
        formula = Formula[changed_formulae_names.first]
        new_versions = current_versions_from_info_external(patch_changes[:formulae].first)
        orig_subject = message.empty? ? "" : message.lines.first.chomp
        bump_subject = subject_for_bump(formula, old_versions, new_versions)
        if do_bump
          odie "No version changes found for #{formula.name}" if bump_subject.nil?
          unless orig_subject == bump_subject
            ohai "New bump commit subject: #{bump_subject}"
            pbcopy bump_subject unless args.no_pbcopy?
            message = "#{bump_subject}\n\n#{message}"
          end
        elsif bump_subject != orig_subject && !bump_subject.nil?
          opoo "Nonstandard bump subject: #{orig_subject}"
          opoo "Subject should be: #{bump_subject}"
        end
      end

      if message != orig_message && !args.clean?
        safe_system "git", "commit", "--amend", "--signoff", "--allow-empty", "-q", "-m", message
      end

      # Bottles: Pull bottle block commit and publish bottle files on Bintray
      if fetch_bottles
        bottle_commit_url = if testing_job
          bottle_branch = "testing-bottle-#{testing_job}"
          url
        else
          bottle_branch = "pull-bottle-#{issue}"
          bot_username = GitHub.test_bot_user(user, args.test_bot_user)
          "https://github.com/#{bot_username}/homebrew-#{tap.repo}/compare/#{user}:master...pr-#{issue}"
        end

        curl "--silent", "--fail", "--output", "/dev/null", "--head", bottle_commit_url

        pr_head = Utils.popen_read("git", "rev-parse", "HEAD").chomp
        safe_system "git", "checkout", "--quiet", "-B", bottle_branch, orig_revision
        pull_patch bottle_commit_url, "bottle commit"
        safe_system "git", "rebase", "--quiet", branch
        safe_system "git", "checkout", "--quiet", branch
        safe_system "git", "merge", "--quiet", "--ff-only", "--no-edit", bottle_branch
        safe_system "git", "branch", "--quiet", "-D", bottle_branch

        if Utils.popen_read("git", "rev-list", "--parents", "-n1", pr_head).count(" ") > 1
          # Publish and verify bottles for those formulae whose bottles were updated.
          changed_formulae_names = Utils.popen_read(
            "git", "diff-tree", "-r", "--name-only",
            "--diff-filter=AM", pr_head, branch, "--", tap.formula_dir
          ).lines.map { |s| File.basename(s, ".rb\n") if s.end_with? ".rb\n" }.compact
        end

        # Publish bottles on Bintray
        unless args.no_publish?
          published = publish_changed_formula_bottles(tap, changed_formulae_names)
          bintray_published_formulae.concat(published)
        end

        # Squash a Linuxbrew build-bottle-pr commit.
        if Utils.popen_read("git", "diff", orig_revision, "HEAD") =~ /^\+# .*: Build a bottle for Linuxbrew$/
          ohai "Squashing build-bottle-pr commit"
          tap.install unless (tap = Tap.new("Linuxbrew", "developer")).installed?
          safe_system HOMEBREW_BREW_FILE, "squash-bottle-pr"
        end
      end

      ohai "Patch changed:"
      safe_system "git", "diff-tree", "-r", "--stat", orig_revision, "HEAD"
    end

    # Verify bintray publishing after all patches have been applied
    bintray_published_formulae.uniq!
    verify_bintray_published(bintray_published_formulae)
    ohai "Published bottles for:"
    puts bintray_published_formulae.join " "
  end

  def force_utf8!(str)
    str.force_encoding("UTF-8") if str.respond_to?(:force_encoding)
  end

  def publish_changed_formula_bottles(tap, changed_formulae_names)
    if ENV["HOMEBREW_DISABLE_LOAD_FORMULA"]
      raise "Need to load formulae to publish them!"
    end

    published = []
    bintray_creds = { user: ENV["HOMEBREW_BINTRAY_USER"], key: ENV["HOMEBREW_BINTRAY_KEY"] }
    if bintray_creds[:user] && bintray_creds[:key]
      changed_formulae_names.each do |name|
        f = Formula[name]
        next if f.bottle_unneeded? || f.bottle_disabled?

        bintray_org = args.bintray_org || tap.user.downcase
        next unless publish_bottle_file_on_bintray(f, bintray_org, bintray_creds)

        published << f.full_name
      end
    else
      opoo "You must set HOMEBREW_BINTRAY_USER and HOMEBREW_BINTRAY_KEY to add or update bottles on Bintray!"
    end
    published
  end

  def pull_patch(url, description = nil)
    PatchPuller.new(url, args, description).pull_patch
  end

  class PatchPuller
    attr_reader :base_url
    attr_reader :patch_url
    attr_reader :patchpath

    def initialize(url, args, description = nil)
      @base_url = url
      # GitHub provides commits/pull-requests raw patches using this URL.
      @patch_url = url + ".patch"
      @patchpath = HOMEBREW_CACHE + File.basename(patch_url)
      @description = description
      @args = args
    end

    def pull_patch
      fetch_patch
      apply_patch
    end

    def fetch_patch
      extra_msg = @description ? "(#{@description})" : nil
      ohai "Fetching patch #{extra_msg}"
      puts "Patch: #{patch_url}"
      curl_download patch_url, to: patchpath
    end

    def apply_patch
      # Applies a patch previously downloaded with fetch_patch()
      # Deletes the patch file as a side effect, regardless of success

      issue = patch_url[/([0-9]+)\.patch$/, 1]
      safe_system "git", "fetch", "--quiet", "origin", "pull/#{issue}/head"
      if Utils.popen_read("git", "rev-list", "--parents", "-n1", "FETCH_HEAD").count(" ") > 1
        patchpath.unlink
        ohai "Fast-forwarding to the merge commit"
        test_bot_origin = patch_url[%r{(https://github\.com/[\w-]+/[\w-]+)/compare/}, 1]
        safe_system "git", "fetch", "--quiet", test_bot_origin, "pr-#{issue}" if test_bot_origin
        system "git", "merge", "--quiet", "--ff-only", "--no-edit", "FETCH_HEAD"
        unless $CHILD_STATUS.success?
          opoo "Not possible to fast-forward, using git reset --hard"
          safe_system "git", "reset", "--hard", "FETCH_HEAD"
        end
        return
      end

      ohai "Applying patch"
      patch_args = []
      # Normally we don't want whitespace errors, but squashing them can break
      # patches so an option is provided to skip this step.
      if @args.ignore_whitespace? || @args.clean?
        patch_args << "--whitespace=nowarn"
      else
        patch_args << "--whitespace=fix"
      end

      # Fall back to three-way merge if patch does not apply cleanly
      patch_args << "-3"
      patch_args << patchpath

      begin
        safe_system "git", "am", *patch_args
      rescue ErrorDuringExecution
        if @args.resolve?
          odie "Patch failed to apply: try to resolve it."
        else
          system "git", "am", "--abort"
          odie "Patch failed to apply: aborted."
        end
      ensure
        patchpath.unlink
      end
    end
  end

  # List files changed by a patch, partitioned in to those that are (probably)
  # formula definitions, and those which aren't. Only applies to patches on
  # Homebrew core or taps, based simply on relative pathnames of affected files.
  def files_changed_in_patch(patchfile, tap)
    files = []
    formulae = []
    others = []
    File.foreach(patchfile) do |line|
      files << Regexp.last_match(1) if line =~ %r{^\+\+\+ b/(.*)}
    end
    files.each do |file|
      if tap&.formula_file?(file)
        formula_name = File.basename(file, ".rb")
        formulae << formula_name unless formulae.include?(formula_name)
      else
        others << file
      end
    end
    { files: files, formulae: formulae, others: others }
  end

  # Get current formula versions without loading formula definition in this process.
  # Returns info as a hash (type => version), for pull.rb's internal use.
  # Uses special key `:nonexistent => true` for nonexistent formulae.
  def current_versions_from_info_external(formula_name)
    info = FormulaInfoFromJson.lookup(formula_name)
    versions = {}
    if info
      [:stable, :devel, :head].each do |spec_type|
        versions[spec_type] = info.version(spec_type)
      end
    else
      versions[:nonexistent] = true
    end
    versions
  end

  def subject_for_bump(formula, old, new)
    if old[:nonexistent]
      # New formula
      headline_ver = if new[:stable]
        new[:stable]
      elsif new[:devel]
        new[:devel]
      else
        new[:head]
      end
      subject = "#{formula.name} #{headline_ver} (new formula)"
    else
      # Update to existing formula
      subject_strs = []
      formula_name_str = formula.name
      if old[:stable] != new[:stable]
        if new[:stable].nil?
          subject_strs << "remove stable"
          formula_name_str += ":" # just for cosmetics
        else
          subject_strs << new[:stable]
        end
      end
      if old[:devel] != new[:devel]
        if new[:devel].nil?
          # Only bother mentioning if there's no accompanying stable change
          if !new[:stable].nil? && old[:stable] == new[:stable]
            subject_strs << "remove devel"
            formula_name_str += ":" # just for cosmetics
          end
        else
          subject_strs << "#{new[:devel]} (devel)"
        end
      end
      subject = subject_strs.empty? ? nil : "#{formula_name_str} #{subject_strs.join(", ")}"
    end
    subject
  end

  def pbcopy(text)
    Utils.popen_write("pbcopy") { |io| io.write text }
  end

  # Publishes the current bottle files for a given formula to Bintray
  def publish_bottle_file_on_bintray(f, bintray_org, creds)
    repo = Utils::Bottles::Bintray.repository(f.tap)
    package = Utils::Bottles::Bintray.package(f.name)
    info = FormulaInfoFromJson.lookup(f.full_name)
    if info.nil?
      raise "Failed publishing bottle: failed reading formula info for #{f.full_name}"
    end

    unless info.bottle_info_any
      opoo "No bottle defined in formula #{package}"
      return false
    end
    version = info.pkg_version
    ohai "Publishing on Bintray: #{package} #{version}"
    curl "--write-out", '\n', "--silent", "--fail",
         "--user", "#{creds[:user]}:#{creds[:key]}", "--request", "POST",
         "--header", "Content-Type: application/json",
         "--data", '{"publish_wait_for_secs": 0}',
         "https://api.bintray.com/content/#{bintray_org}/#{repo}/#{package}/#{version}/publish"
    true
  rescue => e
    raise unless @args.warn_on_publish_failure?

    onoe e
    false
  end

  # Formula info drawn from an external `brew info --json` call
  class FormulaInfoFromJson
    # The whole info structure parsed from the JSON
    attr_accessor :info

    def initialize(info)
      @info = info
    end

    # Looks up formula on disk and reads its info.
    # Returns nil if formula is absent or if there was an error reading it.
    def self.lookup(name)
      json = Utils.popen_read(HOMEBREW_BREW_FILE, "info", "--json=v1", name)

      return unless $CHILD_STATUS.success?

      Homebrew.force_utf8!(json)
      FormulaInfoFromJson.new(JSON.parse(json)[0])
    end

    def bottle_tags
      return [] unless info["bottle"]["stable"]

      info["bottle"]["stable"]["files"].keys
    end

    def bottle_info(my_bottle_tag = Utils::Bottles.tag)
      tag_s = my_bottle_tag.to_s
      return unless info["bottle"]["stable"]

      btl_info = info["bottle"]["stable"]["files"][tag_s]
      return unless btl_info

      BottleInfo.new(btl_info["url"], btl_info["sha256"])
    end

    def bottle_info_any
      bottle_info(any_bottle_tag)
    end

    def any_bottle_tag
      tag = Utils::Bottles.tag.to_s
      # Prefer native bottles as a convenience for download caching
      bottle_tags.include?(tag) ? tag : bottle_tags.first
    end

    def version(spec_type)
      version_str = info["versions"][spec_type.to_s]
      version_str && Version.create(version_str)
    end

    def pkg_version(spec_type = :stable)
      PkgVersion.new(version(spec_type), revision)
    end

    def revision
      info["revision"]
    end
  end

  # Bottle info as used internally by pull, with alternate platform support.
  class BottleInfo
    # URL of bottle as string
    attr_accessor :url
    # Expected SHA-256 as string
    attr_accessor :sha256

    def initialize(url, sha256)
      @url = url
      @sha256 = sha256
    end
  end

  # Verifies that formulae have been published on Bintray by downloading a bottle file
  # for each one. Blocks until the published files are available.
  # Raises an error if the verification fails.
  # This does not currently work for `brew pull`, because it may have cached the old
  # version of a formula.
  def verify_bintray_published(formulae_names)
    return if formulae_names.empty?

    if ENV["HOMEBREW_DISABLE_LOAD_FORMULA"]
      raise "Need to load formulae to verify their publication!"
    end

    ohai "Verifying bottles published on Bintray"
    formulae = formulae_names.map { |n| Formula[n] }
    max_retries = 300 # shared among all bottles
    poll_retry_delay_seconds = 2

    HOMEBREW_CACHE.cd do
      formulae.each do |f|
        retry_count = 0
        wrote_dots = false
        # Choose arbitrary bottle just to get the host/port for Bintray right
        jinfo = FormulaInfoFromJson.lookup(f.full_name)
        unless jinfo
          opoo "Cannot publish bottle: Failed reading info for formula #{f.full_name}"
          next
        end
        bottle_info = jinfo.bottle_info_any
        unless bottle_info
          opoo "No bottle defined in formula #{f.full_name}"
          next
        end

        # Poll for publication completion using a quick partial HEAD, to avoid spurious error messages
        # 401 error is normal while file is still in async publishing process
        url = URI(bottle_info.url)
        puts "Verifying bottle: #{File.basename(url.path)}"
        http = Net::HTTP.new(url.host, url.port)
        http.use_ssl = true
        retry_count = 0
        http.start do
          loop do
            req = Net::HTTP::Head.new bottle_info.url
            req.initialize_http_header "User-Agent" => HOMEBREW_USER_AGENT_RUBY
            res = http.request req
            break if res.is_a?(Net::HTTPSuccess) || res.code == "302"

            unless res.is_a?(Net::HTTPClientError)
              raise "Failed to find published #{f} bottle at #{url} (#{res.code} #{res.message})!"
            end

            if retry_count >= max_retries
              raise "Failed to find published #{f} bottle at #{url}!"
            end

            print(wrote_dots ? "." : "Waiting on Bintray.")
            wrote_dots = true
            sleep poll_retry_delay_seconds
            retry_count += 1
          end
        end

        # Actual download and verification
        # We do a retry on this, too, because sometimes the external curl will fail even
        # when the prior HEAD has succeeded.
        puts "\n" if wrote_dots
        filename = File.basename(url.path)
        curl_retry_delay_seconds = 4
        max_curl_retries = 1
        retry_count = 0
        # We're in the cache; make sure to force re-download
        loop do
          begin
            curl_download url, to: filename
            break
          rescue
            if retry_count >= max_curl_retries
              raise "Failed to download #{f} bottle from #{url}!"
            end

            puts "curl download failed; retrying in #{curl_retry_delay_seconds} sec"
            sleep curl_retry_delay_seconds
            curl_retry_delay_seconds *= 2
            retry_count += 1
          end
        end
        checksum = Checksum.new(:sha256, bottle_info.sha256)
        Pathname.new(filename).verify_checksum(checksum)
      end
    end
  end

  def check_bintray_mirror(name, url)
    headers, = curl_output("--connect-timeout", "15", "--location", "--head", url)
    status_code = headers.scan(%r{^HTTP\/.* (\d+)}).last.first
    return if status_code.start_with?("2")

    opoo "The Bintray mirror #{url} is not reachable (HTTP status code #{status_code})."
    opoo "Do you need to upload it with `brew mirror #{name}`?"
  end
end
