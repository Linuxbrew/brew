def analytics_label
  @analytics_anonymous_prefix_and_os ||= begin
    os = OS_VERSION
    prefix = ", non-/usr/local" if HOMEBREW_PREFIX.to_s != "/usr/local"
    ci = ", CI" if ENV["CI"]
    "#{os}#{prefix}#{ci}"
  end
end

def report_analytics(type, metadata = {})
  return if ENV["HOMEBREW_NO_ANALYTICS"]

  args = %W[
    --max-time 3
    --user-agent #{HOMEBREW_USER_AGENT_CURL}
    -d v=1
    -d tid=#{ENV["HOMEBREW_ANALYTICS_ID"]}
    -d cid=#{ENV["HOMEBREW_ANALYTICS_USER_UUID"]}
    -d aip=1
    -d an=#{HOMEBREW_PRODUCT}
    -d av=#{HOMEBREW_VERSION}
    -d t=#{type}
  ]
  metadata.each { |k, v| args << "-d" << "#{k}=#{v}" if k && v }

  # Send analytics. Don't send or store any personally identifiable information.
  # https://github.com/Homebrew/brew/blob/master/share/doc/homebrew/Analytics.md
  # https://developers.google.com/analytics/devguides/collection/protocol/v1/devguide
  # https://developers.google.com/analytics/devguides/collection/protocol/v1/parameters
  if ENV["HOMEBREW_ANALYTICS_DEBUG"]
    puts Utils.popen_read ENV["HOMEBREW_CURL"],
      "https://www.google-analytics.com/debug/collect",
      *args
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

def report_analytics_event(category, action, label = analytics_label, value = nil)
  report_analytics(:event,
    :ec => category,
    :ea => action,
    :el => label,
    :ev => value)
end

def report_analytics_exception(exception, options = {})
  if exception.is_a?(BuildError) &&
     exception.formula.tap && !exception.formula.tap.private?
    report_analytics_event("BuildError", exception.formula.full_name)
  end

  fatal = options.fetch(:fatal, true) ? "1" : "0"
  report_analytics(:exception,
    :exd => exception.class.name,
    :exf => fatal)
end

def report_analytics_screenview(screen_name)
  report_analytics(:screenview, :cd => screen_name)
end
