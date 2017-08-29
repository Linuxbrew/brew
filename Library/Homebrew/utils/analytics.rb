require "erb"

module Utils
  module Analytics
    class << self
      def clear_anonymous_os_prefix_ci_cache
        return unless instance_variable_defined?(:@anonymous_os_prefix_ci)
        remove_instance_variable(:@anonymous_os_prefix_ci)
      end

      def os_prefix_ci
        @anonymous_os_prefix_ci ||= begin
          os = OS_VERSION
          prefix = ", non-/usr/local" if HOMEBREW_PREFIX.to_s != "/usr/local"
          ci = ", CI" if ENV["CI"]
          "#{os}#{prefix}#{ci}"
        end
      end

      def report(type, metadata = {})
        return if ENV["HOMEBREW_NO_ANALYTICS"] || ENV["HOMEBREW_NO_ANALYTICS_THIS_RUN"]

        args = %W[
          --max-time 3
          --user-agent #{HOMEBREW_USER_AGENT_CURL}
          --data v=1
          --data aip=1
          --data t=#{type}
          --data tid=#{ENV["HOMEBREW_ANALYTICS_ID"]}
          --data cid=#{ENV["HOMEBREW_ANALYTICS_USER_UUID"]}
          --data an=#{HOMEBREW_PRODUCT}
          --data av=#{HOMEBREW_VERSION}
        ]
        metadata.each do |key, value|
          next unless key
          next unless value
          key = ERB::Util.url_encode key
          value = ERB::Util.url_encode value
          args << "--data" << "#{key}=#{value}"
        end

        # Send analytics. Don't send or store any personally identifiable information.
        # https://docs.brew.sh/Analytics.html
        # https://developers.google.com/analytics/devguides/collection/protocol/v1/devguide
        # https://developers.google.com/analytics/devguides/collection/protocol/v1/parameters
        if ENV["HOMEBREW_ANALYTICS_DEBUG"]
          url = "https://www.google-analytics.com/debug/collect"
          puts "#{ENV["HOMEBREW_CURL"]} #{url} #{args.join(" ")}"
          puts Utils.popen_read ENV["HOMEBREW_CURL"], url, *args
        else
          pid = fork do
            exec ENV["HOMEBREW_CURL"],
              "https://www.google-analytics.com/collect",
              "--silent", "--output", "/dev/null",
              *args
          end
          Process.detach pid
        end
      end

      def report_event(category, action, label = os_prefix_ci, value = nil)
        report(:event,
          ec: category,
          ea: action,
          el: label,
          ev: value)
      end

      def report_build_error(exception)
        return unless exception.formula.tap
        return unless exception.formula.tap.installed?
        return if exception.formula.tap.private?
        action = exception.formula.full_name
        if (options = exception.options)
          action = "#{action} #{options}".strip
        end
        report_event("BuildError", action)
      end
    end
  end
end
