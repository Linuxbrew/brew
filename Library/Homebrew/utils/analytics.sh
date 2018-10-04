# Migrate analytics UUID to its new home in Homebrew repo's git config and
# remove the legacy UUID file if detected.
migrate-legacy-uuid-file() {
  local legacy_uuid_file analytics_uuid

  legacy_uuid_file="$HOME/.homebrew_analytics_user_uuid"

  if [[ -f "$legacy_uuid_file" ]]
  then
    analytics_uuid="$(<"$legacy_uuid_file")"
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

  local message_seen analytics_disabled
  message_seen="$(git config --file="$git_config_file" --get homebrew.analyticsmessage 2>/dev/null)"
  analytics_disabled="$(git config --file="$git_config_file" --get homebrew.analyticsdisabled 2>/dev/null)"
  if [[ "$message_seen" != "true" || "$analytics_disabled" = "true" ]]
  then
    # Internal variable for brew's use, to differentiate from user-supplied setting
    export HOMEBREW_NO_ANALYTICS_THIS_RUN="1"
    return
  fi

  HOMEBREW_ANALYTICS_USER_UUID="$(git config --file="$git_config_file" --get homebrew.analyticsuuid 2>/dev/null)"
  if [[ -z "$HOMEBREW_ANALYTICS_USER_UUID" ]]
  then
    if [[ -x /usr/bin/uuidgen ]]
    then
      HOMEBREW_ANALYTICS_USER_UUID="$(/usr/bin/uuidgen)"
    elif [[ -r /proc/sys/kernel/random/uuid ]]
    then
      HOMEBREW_ANALYTICS_USER_UUID="$(tr a-f A-F </proc/sys/kernel/random/uuid)"
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
