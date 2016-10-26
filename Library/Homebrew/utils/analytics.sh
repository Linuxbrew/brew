# Migrate analytics UUID to its new home in Homebrew repo's git config and
# remove the legacy UUID file if detected.
migrate-legacy-uuid-file() {
  local legacy_uuid_file="$HOME/.homebrew_analytics_user_uuid"
  if [[ -f "$legacy_uuid_file" ]]
  then
    local analytics_uuid="$(<"$legacy_uuid_file")"
    if [[ -n "$analytics_uuid" ]]
    then
      git config --file="$HOMEBREW_REPOSITORY/.git/config" --replace-all homebrew.analyticsuuid "$analytics_uuid" 2>/dev/null
    fi
    rm -f "$legacy_uuid_file"
  fi
}

setup-analytics() {
  local git_config_file="$HOMEBREW_REPOSITORY/.git/config"

  migrate-legacy-uuid-file

  if [[ -n "$HOMEBREW_NO_ANALYTICS" ]]
  then
    return
  fi

  local message_seen="$(git config --file="$git_config_file" --get homebrew.analyticsmessage 2>/dev/null)"
  local analytics_disabled="$(git config --file="$git_config_file" --get homebrew.analyticsdisabled 2>/dev/null)"
  if [[ "$message_seen" != "true" || "$analytics_disabled" = "true" ]]
  then
    # Internal variable for brew's use, to differentiate from user-supplied setting
    export HOMEBREW_NO_ANALYTICS_THIS_RUN="1"
    return
  fi

  HOMEBREW_ANALYTICS_USER_UUID="$(git config --file="$git_config_file" --get homebrew.analyticsuuid 2>/dev/null)"
  if [[ -z "$HOMEBREW_ANALYTICS_USER_UUID" ]]
  then
    if [[ -n "$HOMEBREW_LINUX" ]]
    then
      HOMEBREW_ANALYTICS_USER_UUID="$(tr a-f A-F </proc/sys/kernel/random/uuid)"
    elif [[ -n "$HOMEBREW_MACOS" ]]
    then
      HOMEBREW_ANALYTICS_USER_UUID="$(/usr/bin/uuidgen)"
    else
      HOMEBREW_ANALYTICS_USER_UUID="$(uuidgen)"
    fi

    if [[ -z "$HOMEBREW_ANALYTICS_USER_UUID" ]]
    then
      # Avoid sending bogus analytics if no UUID could be generated.
      export HOMEBREW_NO_ANALYTICS_THIS_RUN="1"
      return
    fi
    git config --file="$git_config_file" --replace-all homebrew.analyticsuuid "$HOMEBREW_ANALYTICS_USER_UUID" 2>/dev/null
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
  [[ -n "$HOMEBREW_NO_ANALYTICS" || -n "$HOMEBREW_NO_ANALYTICS_THIS_RUN" ]] && return

  # Don't report commands that are invoked as part of other commands.
  [[ "$HOMEBREW_COMMAND_DEPTH" != 1 ]] && return

  # Don't report non-official commands.
  if ! [[ "$HOMEBREW_COMMAND" = "bundle"   ||
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
  case "$HOMEBREW_COMMAND" in
    --prefix|analytics|command|commands)
      return
      ;;
  esac

  local args=(
    --max-time 3
    --user-agent "$HOMEBREW_USER_AGENT_CURL"
    --data v=1
    --data aip=1
    --data t=screenview
    --data tid="$HOMEBREW_ANALYTICS_ID"
    --data cid="$HOMEBREW_ANALYTICS_USER_UUID"
    --data an="$HOMEBREW_PRODUCT"
    --data av="$HOMEBREW_VERSION"
    --data cd="$HOMEBREW_COMMAND"
  )

  # Send analytics. Don't send or store any personally identifiable information.
  # https://github.com/Homebrew/brew/blob/master/docs/Analytics.md
  # https://developers.google.com/analytics/devguides/collection/protocol/v1/devguide#screenView
  # https://developers.google.com/analytics/devguides/collection/protocol/v1/parameters
  if [[ -z "$HOMEBREW_ANALYTICS_DEBUG" ]]
  then
    "$HOMEBREW_CURL" https://www.google-analytics.com/collect \
      "${args[@]}" \
      --silent --output /dev/null &>/dev/null & disown
  else
    local url="https://www.google-analytics.com/debug/collect"
    echo "$HOMEBREW_CURL $url ${args[*]}"
    "$HOMEBREW_CURL" "$url" "${args[@]}"
  fi
}
