setup-analytics() {
  [[ -n "$HOMEBREW_NO_ANALYTICS" ]] && return

  # User UUID file. Used for Homebrew user counting. Can be deleted and
  # recreated with no adverse effect (beyond our user counts being inflated).
  HOMEBREW_ANALYTICS_USER_UUID_FILE="$HOME/.homebrew_analytics_user_uuid"
  if [[ -r "$HOMEBREW_ANALYTICS_USER_UUID_FILE" ]]
  then
    HOMEBREW_ANALYTICS_USER_UUID="$(<"$HOMEBREW_ANALYTICS_USER_UUID_FILE")"
  else
    HOMEBREW_ANALYTICS_USER_UUID="$(uuidgen)"
    echo "$HOMEBREW_ANALYTICS_USER_UUID" > "$HOMEBREW_ANALYTICS_USER_UUID_FILE"
  fi

  if [[ -n "$HOMEBREW_LINUX" ]]
  then
    # For Linuxbrew's analytics.
    HOMEBREW_ANALYTICS_ID="UA-76492262-1"
  else
    # Otherwise, fall back to Homebrew's analytics.
    HOMEBREW_ANALYTICS_ID="UA-76679469-1"
  fi

  export HOMEBREW_ANALYTICS_ID
  export HOMEBREW_ANALYTICS_USER_UUID
}

report-analytics-screenview-command() {
  [[ -n "$HOMEBREW_NO_ANALYTICS" ]] && return

  # Don't report non-official commands.
  if ! [[ "$HOMEBREW_COMMAND" = "bundle"   ||
          "$HOMEBREW_COMMAND" = "cask"     ||
          "$HOMEBREW_COMMAND" = "services" ||
          -f "$HOMEBREW_LIBRARY/Homebrew/cmd/$HOMEBREW_COMMAND.rb"     ||
          -f "$HOMEBREW_LIBRARY/Homebrew/cmd/$HOMEBREW_COMMAND.sh"     ||
          -f "$HOMEBREW_LIBRARY/Homebrew/dev-cmd/$HOMEBREW_COMMAND.rb" ||
          -f "$HOMEBREW_LIBRARY/Homebrew/dev-cmd/$HOMEBREW_COMMAND.sh" ]]
  then
    return
  fi

  # Don't report commands used mostly by our scripts and not users.
  # TODO: list more e.g. shell completion things here perhaps using a single
  # script as a shell-completion entry point.
  if [[ "$HOMEBREW_COMMAND" = "commands" ]]
  then
    return
  fi

  local args=(
    --max-time 3 \
    --user-agent "$HOMEBREW_USER_AGENT_CURL" \
    -d v=1 \
    -d tid="$HOMEBREW_ANALYTICS_ID" \
    -d cid="$HOMEBREW_ANALYTICS_USER_UUID" \
    -d aip=1 \
    -d an="$HOMEBREW_PRODUCT" \
    -d av="$HOMEBREW_VERSION" \
    -d t=screenview \
    -d cd="$HOMEBREW_COMMAND" \
  )

  # Send analytics. Don't send or store any personally identifiable information.
  # https://github.com/Homebrew/brew/blob/master/share/doc/homebrew/Analytics.md
  # https://developers.google.com/analytics/devguides/collection/protocol/v1/devguide#screenView
  # https://developers.google.com/analytics/devguides/collection/protocol/v1/parameters
  if [[ -z "$HOMEBREW_ANALYTICS_DEBUG" ]]
  then
    "$HOMEBREW_CURL" https://www.google-analytics.com/collect \
      "${args[@]}" \
      --silent --output /dev/null &>/dev/null & disown
  else
    "$HOMEBREW_CURL" https://www.google-analytics.com/debug/collect \
      "${args[@]}"
  fi
}
