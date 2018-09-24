#:  * `analytics` [`state`]:
#:    Display anonymous user behaviour analytics state.
#:    Read more at <https://docs.brew.sh/Analytics>.
#:
#:  * `analytics` (`on`|`off`):
#:    Turn on/off Homebrew's analytics.
#:
#:  * `analytics` `regenerate-uuid`:
#:    Regenerate UUID used in Homebrew's analytics.

module Homebrew
  module_function

  def analytics
    config_file = HOMEBREW_REPOSITORY/".git/config"

    raise UsageError if ARGV.named.size > 1

    case ARGV.named.first
    when nil, "state"
      analyticsdisabled = \
        Utils.popen_read("git config --file=#{config_file} --get homebrew.analyticsdisabled").chuzzle
      uuid = \
        Utils.popen_read("git config --file=#{config_file} --get homebrew.analyticsuuid").chuzzle
      if ENV["HOMEBREW_NO_ANALYTICS"]
        puts "Analytics is disabled (by HOMEBREW_NO_ANALYTICS)."
      elsif analyticsdisabled == "true"
        puts "Analytics is disabled."
      else
        puts "Analytics is enabled."
        puts "UUID: #{uuid}" if uuid
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
