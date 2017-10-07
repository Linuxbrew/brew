require "hbc/checkable"
require "hbc/download"
require "digest"
require "utils/git"

module Hbc
  class Audit
    include Checkable

    attr_reader :cask, :commit_range, :download

    def initialize(cask, download: false, check_token_conflicts: false, commit_range: nil, command: SystemCommand)
      @cask = cask
      @download = download
      @commit_range = commit_range
      @check_token_conflicts = check_token_conflicts
      @command = command
    end

    def check_token_conflicts?
      @check_token_conflicts
    end

    def run!
      check_required_stanzas
      check_version_and_checksum
      check_version
      check_sha256
      check_appcast
      check_url
      check_generic_artifacts
      check_token_conflicts
      check_download
      self
    rescue StandardError => e
      odebug "#{e.message}\n#{e.backtrace.join("\n")}"
      add_error "exception while auditing #{cask}: #{e.message}"
      self
    end

    def success?
      !(errors? || warnings?)
    end

    def summary_header
      "audit for #{cask}"
    end

    private

    def check_required_stanzas
      odebug "Auditing required stanzas"
      [:version, :sha256, :url, :homepage].each do |sym|
        add_error "a #{sym} stanza is required" unless cask.send(sym)
      end
      add_error "at least one name stanza is required" if cask.name.empty?
      # TODO: specific DSL knowledge should not be spread around in various files like this
      # TODO: nested_container should not still be a pseudo-artifact at this point
      installable_artifacts = cask.artifacts.reject { |k| [:uninstall, :zap, :nested_container].include?(k) }
      add_error "at least one activatable artifact stanza is required" if installable_artifacts.empty?
    end

    def check_version_and_checksum
      return if @cask.sourcefile_path.nil?

      tap = Tap.select { |t| t.cask_file?(@cask.sourcefile_path) }.first
      return if tap.nil?

      return if commit_range.nil?
      previous_cask_contents = Git.last_revision_of_file(tap.path, @cask.sourcefile_path, before_commit: commit_range)
      return if previous_cask_contents.empty?

      previous_cask = CaskLoader.load_from_string(previous_cask_contents)

      return unless previous_cask.version == cask.version
      return if previous_cask.sha256 == cask.sha256

      add_error "only sha256 changed (see: https://github.com/caskroom/homebrew-cask/blob/master/doc/cask_language_reference/stanzas/sha256.md)"
    end

    def check_version
      return unless cask.version
      check_no_string_version_latest
      check_no_file_separator_in_version
    end

    def check_no_string_version_latest
      odebug "Verifying version :latest does not appear as a string ('latest')"
      return unless cask.version.raw_version == "latest"
      add_error "you should use version :latest instead of version 'latest'"
    end

    def check_no_file_separator_in_version
      odebug "Verifying version does not contain '#{File::SEPARATOR}'"
      return unless cask.version.raw_version.is_a?(String)
      return unless cask.version.raw_version.include?(File::SEPARATOR)
      add_error "version should not contain '#{File::SEPARATOR}'"
    end

    def check_sha256
      return unless cask.sha256
      check_sha256_no_check_if_latest
      check_sha256_actually_256
      check_sha256_invalid
    end

    def check_sha256_no_check_if_latest
      odebug "Verifying sha256 :no_check with version :latest"
      return unless cask.version.latest? && cask.sha256 != :no_check
      add_error "you should use sha256 :no_check when version is :latest"
    end

    def check_sha256_actually_256(sha256: cask.sha256, stanza: "sha256")
      odebug "Verifying #{stanza} string is a legal SHA-256 digest"
      return unless sha256.is_a?(String)
      return if sha256.length == 64 && sha256[/^[0-9a-f]+$/i]
      add_error "#{stanza} string must be of 64 hexadecimal characters"
    end

    def check_sha256_invalid(sha256: cask.sha256, stanza: "sha256")
      odebug "Verifying #{stanza} is not a known invalid value"
      empty_sha256 = "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
      return unless sha256 == empty_sha256
      add_error "cannot use the sha256 for an empty string in #{stanza}: #{empty_sha256}"
    end

    def check_appcast
      return unless cask.appcast
      odebug "Auditing appcast"
      check_appcast_has_checkpoint
      return unless cask.appcast.checkpoint
      check_sha256_actually_256(sha256: cask.appcast.checkpoint, stanza: "appcast :checkpoint")
      check_sha256_invalid(sha256: cask.appcast.checkpoint, stanza: "appcast :checkpoint")
      return unless download
      check_appcast_http_code
      check_appcast_checkpoint_accuracy
    end

    def check_appcast_has_checkpoint
      odebug "Verifying appcast has :checkpoint key"
      add_error "a checkpoint sha256 is required for appcast" unless cask.appcast.checkpoint
    end

    def check_appcast_http_code
      odebug "Verifying appcast returns 200 HTTP response code"

      curl_executable, *args = curl_args(
        "--compressed", "--location", "--fail",
        "--write-out", "%{http_code}",
        "--output", "/dev/null",
        cask.appcast,
        user_agent: :fake
      )
      result = @command.run(curl_executable, args: args, print_stderr: false)
      if result.success?
        http_code = result.stdout.chomp
        add_warning "unexpected HTTP response code retrieving appcast: #{http_code}" unless http_code == "200"
      else
        add_warning "error retrieving appcast: #{result.stderr}"
      end
    end

    def check_appcast_checkpoint_accuracy
      odebug "Verifying appcast checkpoint is accurate"
      result = cask.appcast.calculate_checkpoint

      actual_checkpoint = result[:checkpoint]

      if actual_checkpoint.nil?
        add_warning "error retrieving appcast: #{result[:command_result].stderr}"
      else
        expected = cask.appcast.checkpoint
        add_warning <<-EOS.undent unless expected == actual_checkpoint
          appcast checkpoint mismatch
          Expected: #{expected}
          Actual: #{actual_checkpoint}
        EOS
      end
    end

    def check_url
      return unless cask.url
      check_download_url_format
    end

    def check_download_url_format
      odebug "Auditing URL format"
      if bad_sourceforge_url?
        add_warning "SourceForge URL format incorrect. See https://github.com/caskroom/homebrew-cask/blob/master/doc/cask_language_reference/stanzas/url.md#sourceforgeosdn-urls"
      elsif bad_osdn_url?
        add_warning "OSDN URL format incorrect. See https://github.com/caskroom/homebrew-cask/blob/master/doc/cask_language_reference/stanzas/url.md#sourceforgeosdn-urls"
      end
    end

    def bad_url_format?(regex, valid_formats_array)
      return false unless cask.url.to_s =~ regex
      valid_formats_array.none? { |format| cask.url.to_s =~ format }
    end

    def bad_sourceforge_url?
      bad_url_format?(/sourceforge/,
                      [
                        %r{\Ahttps://sourceforge\.net/projects/[^/]+/files/latest/download\Z},
                        %r{\Ahttps://downloads\.sourceforge\.net/(?!(project|sourceforge)\/)},
                        # special cases: cannot find canonical format URL
                        %r{\Ahttps?://brushviewer\.sourceforge\.net/brushviewql\.zip\Z},
                        %r{\Ahttps?://doublecommand\.sourceforge\.net/files/},
                        %r{\Ahttps?://excalibur\.sourceforge\.net/get\.php\?id=},
                      ])
    end

    def bad_osdn_url?
      bad_url_format?(/osd/, [%r{\Ahttps?://([^/]+.)?dl\.osdn\.jp/}])
    end

    def check_generic_artifacts
      cask.artifacts[:artifact].each do |source, target_hash|
        unless target_hash.is_a?(Hash) && target_hash[:target]
          add_error "target required for generic artifact #{source}"
          next
        end
        add_error "target must be absolute path for generic artifact #{source}" unless Pathname.new(target_hash[:target]).absolute?
      end
    end

    def check_token_conflicts
      return unless check_token_conflicts?
      return unless core_formula_names.include?(cask.token)
      add_warning "possible duplicate, cask token conflicts with Homebrew core formula: #{core_formula_url}"
    end

    def core_tap
      @core_tap ||= CoreTap.instance
    end

    def core_formula_names
      core_tap.formula_names
    end

    def core_formula_url
      "#{core_tap.default_remote}/blob/master/Formula/#{cask.token}.rb"
    end

    def check_download
      return unless download && cask.url
      odebug "Auditing download"
      downloaded_path = download.perform
      Verify.all(cask, downloaded_path)
    rescue => e
      add_error "download not possible: #{e.message}"
    end
  end
end
