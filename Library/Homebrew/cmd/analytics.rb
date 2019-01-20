#:  * `analytics` [`state`]:
#:    Display anonymous user behaviour analytics state.
#:    Read more at <https://docs.brew.sh/Analytics>.
#:
#:  * `analytics` (`on`|`off`):
#:    Turn on/off Homebrew's analytics.
#:
#:  * `analytics` `regenerate-uuid`:
#:    Regenerate UUID used in Homebrew's analytics.

require "cli_parser"

module Homebrew
  module_function

  def analytics_args
    Homebrew::CLI::Parser.new do
      usage_banner <<~EOS
        `analytics` (`on`|`off`) [`state`] [`regenerate-uuid`]

        If `on`|`off` is passed, turn Homebrew's analytics on or off respectively.

        If `state` is passed, display anonymous user behaviour analytics state.
        Read more at <https://docs.brew.sh/Analytics>.

        If `regenerate-uuid` is passed, regenerate UUID used in Homebrew's analytics.
      EOS
      switch :verbose
      switch :debug
    end
  end

  def analytics
    analytics_args.parse
    config_file = HOMEBREW_REPOSITORY/".git/config"

    raise UsageError if args.remaining.size > 1

    case args.remaining.first
    when nil, "state"
      analyticsdisabled =
        Utils.popen_read("git config --file=#{config_file} --get homebrew.analyticsdisabled").chomp
      uuid =
        Utils.popen_read("git config --file=#{config_file} --get homebrew.analyticsuuid").chomp
      if ENV["HOMEBREW_NO_ANALYTICS"]
        puts "Analytics is disabled (by HOMEBREW_NO_ANALYTICS)."
      elsif analyticsdisabled == "true"
        puts "Analytics is disabled."
      else
        puts "Analytics is enabled."
        puts "UUID: #{uuid}" if uuid.present?
      end
    when "on"
      safe_system "git", "config", "--file=#{config_file}",
                                   "--replace-all", "homebrew.analyticsdisabled", "false"
      safe_system "git", "config", "--file=#{config_file}",
                                   "--replace-all", "homebrew.analyticsmessage", "true"
    when "off"
      safe_system "git", "config", "--file=#{config_file}",
                                   "--replace-all", "homebrew.analyticsdisabled", "true"
      system "git", "config", "--file=#{config_file}", "--unset-all", "homebrew.analyticsuuid"
    when "regenerate-uuid"
      # it will be regenerated in next run.
      system "git", "config", "--file=#{config_file}", "--unset-all", "homebrew.analyticsuuid"
    else
      raise UsageError
    end
  end
end
