#:  * `update` [`--merge`] [`--force`]:
#:    Fetch the newest version of Homebrew and all formulae from GitHub using
#:    `git`(1) and perform any necessary migrations.
#:
#:    If `--merge` is specified then `git merge` is used to include updates
#:    (rather than `git rebase`).
#:
#:    If `--force` (or `-f`) is specified then always do a slower, full update check even
#:    if unnecessary.

# Don't need shellcheck to follow this `source`.
# shellcheck disable=SC1090
source "$HOMEBREW_LIBRARY/Homebrew/utils/lock.sh"

# Replaces the function in Library/Homebrew/brew.sh to cache the Git executable to
# provide speedup when using Git repeatedly (as update.sh does).
git() {
  if [[ -z "$GIT_EXECUTABLE" ]]
  then
    GIT_EXECUTABLE="$("$HOMEBREW_LIBRARY/Homebrew/shims/scm/git" --homebrew=print-path)"
  fi
  "$GIT_EXECUTABLE" "$@"
}

git_init_if_necessary() {
  BREW_OFFICIAL_REMOTE="https://github.com/Homebrew/brew"
  if [[ -n "$HOMEBREW_MACOS" ]] || [[ -n "$HOMEBREW_FORCE_HOMEBREW_ON_LINUX" ]]
  then
    CORE_OFFICIAL_REMOTE="https://github.com/Homebrew/homebrew-core"
  else
    CORE_OFFICIAL_REMOTE="https://github.com/Linuxbrew/homebrew-core"
  fi

  safe_cd "$HOMEBREW_REPOSITORY"
  if [[ ! -d ".git" ]]
  then
    set -e
    trap '{ rm -rf .git; exit 1; }' EXIT
    git init
    git config --bool core.autocrlf false
    git config remote.origin.url "$BREW_OFFICIAL_REMOTE"
    git config remote.origin.fetch "+refs/heads/*:refs/remotes/origin/*"
    latest_tag="$(git ls-remote --tags --refs -q origin | tail -n1 | cut -f2)"
    git fetch --force origin --shallow-since="$latest_tag"
    git reset --hard origin/master
    SKIP_FETCH_BREW_REPOSITORY=1
    set +e
    trap - EXIT
  fi

  [[ -d "$HOMEBREW_LIBRARY/Taps/homebrew/homebrew-core" ]] || return
  safe_cd "$HOMEBREW_LIBRARY/Taps/homebrew/homebrew-core"
  if [[ ! -d ".git" ]]
  then
    set -e
    trap '{ rm -rf .git; exit 1; }' EXIT
    git init
    git config --bool core.autocrlf false
    git config remote.origin.url "$CORE_OFFICIAL_REMOTE"
    git config remote.origin.fetch "+refs/heads/*:refs/remotes/origin/*"
    git fetch --force --depth=1 origin refs/heads/master:refs/remotes/origin/master
    git reset --hard origin/master
    SKIP_FETCH_CORE_REPOSITORY=1
    set +e
    trap - EXIT
  fi
}

rename_taps_dir_if_necessary() {
  local tap_dir
  local tap_dir_basename
  local tap_dir_hyphens
  local user
  local repo

  for tap_dir in "$HOMEBREW_LIBRARY"/Taps/*
  do
    [[ -d "$tap_dir/.git" ]] || continue
    tap_dir_basename="${tap_dir##*/}"
    if [[ "$tap_dir_basename" = *"-"* ]]
    then
      # only replace the *last* dash: yes, tap filenames suck
      user="$(echo "${tap_dir_basename%-*}" | tr "[:upper:]" "[:lower:]")"
      repo="$(echo "${tap_dir_basename:${#user}+1}" | tr "[:upper:]" "[:lower:]")"
      mkdir -p "$HOMEBREW_LIBRARY/Taps/$user"
      mv "$tap_dir" "$HOMEBREW_LIBRARY/Taps/$user/homebrew-$repo"

      tap_dir_hyphens="${tap_dir_basename//[^\-]}"
      if [[ ${#tap_dir_hyphens} -gt 1 ]]
      then
        echo "Homebrew changed the structure of Taps like <someuser>/<sometap>." >&2
        echo "So you may need to rename $HOMEBREW_LIBRARY/Taps/$user/homebrew-$repo manually." >&2
      fi
    else
      echo "Homebrew changed the structure of Taps like <someuser>/<sometap>. " >&2
      echo "$tap_dir is an incorrect Tap path." >&2
      echo "So you may need to rename it to $HOMEBREW_LIBRARY/Taps/<someuser>/homebrew-<sometap> manually." >&2
    fi
  done
}

repo_var() {
  local repo_var

  repo_var="$1"
  if [[ "$repo_var" = "$HOMEBREW_REPOSITORY" ]]
  then
    repo_var=""
  else
    repo_var="${repo_var#"$HOMEBREW_LIBRARY/Taps"}"
    repo_var="$(echo -n "$repo_var" | tr -C "A-Za-z0-9" "_" | tr "[:lower:]" "[:upper:]")"
  fi
  echo "$repo_var"
}

upstream_branch() {
  local upstream_branch

  upstream_branch="$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null)"
  upstream_branch="${upstream_branch#refs/remotes/origin/}"
  [[ -z "$upstream_branch" ]] && upstream_branch="master"
  echo "$upstream_branch"
}

read_current_revision() {
  git rev-parse -q --verify HEAD
}

pop_stash() {
  [[ -z "$STASHED" ]] && return
  if [[ -n "$HOMEBREW_VERBOSE" ]]
  then
    echo "Restoring your stashed changes to $DIR..."
    git stash pop
  else
    git stash pop "${QUIET_ARGS[@]}" 1>/dev/null
  fi
  unset STASHED
}

pop_stash_message() {
  [[ -z "$STASHED" ]] && return
  echo "To restore the stashed changes to $DIR run:"
  echo "  'cd $DIR && git stash pop'"
  unset STASHED
}

reset_on_interrupt() {
  if [[ "$INITIAL_BRANCH" != "$UPSTREAM_BRANCH" && -n "$INITIAL_BRANCH" ]]
  then
    git checkout "$INITIAL_BRANCH" "${QUIET_ARGS[@]}"
  fi

  if [[ -n "$INITIAL_REVISION" ]]
  then
    git rebase --abort &>/dev/null
    git merge --abort &>/dev/null
    git reset --hard "$INITIAL_REVISION" "${QUIET_ARGS[@]}"
  fi

  if [[ -n "$HOMEBREW_NO_UPDATE_CLEANUP" ]]
  then
    pop_stash
  else
    pop_stash_message
  fi

  exit 130
}

# Used for testing purposes, e.g., for testing formula migration after
# renaming it in the currently checked-out branch. To test run
# "brew update --simulate-from-current-branch"
simulate_from_current_branch() {
  local DIR
  local TAP_VAR
  local UPSTREAM_BRANCH
  local CURRENT_REVISION

  DIR="$1"
  cd "$DIR" || return
  TAP_VAR="$2"
  UPSTREAM_BRANCH="$3"
  CURRENT_REVISION="$4"

  INITIAL_REVISION="$(git rev-parse -q --verify "$UPSTREAM_BRANCH")"
  export HOMEBREW_UPDATE_BEFORE"$TAP_VAR"="$INITIAL_REVISION"
  export HOMEBREW_UPDATE_AFTER"$TAP_VAR"="$CURRENT_REVISION"
  if [[ "$INITIAL_REVISION" != "$CURRENT_REVISION" ]]
  then
    HOMEBREW_UPDATED="1"
  fi
  if ! git merge-base --is-ancestor "$INITIAL_REVISION" "$CURRENT_REVISION"
  then
    odie "Your $DIR HEAD is not a descendant of $UPSTREAM_BRANCH!"
  fi
}

merge_or_rebase() {
  if [[ -n "$HOMEBREW_VERBOSE" ]]
  then
    echo "Updating $DIR..."
  fi

  local DIR
  local TAP_VAR
  local UPSTREAM_BRANCH

  DIR="$1"
  cd "$DIR" || return
  TAP_VAR="$2"
  UPSTREAM_BRANCH="$3"
  unset STASHED

  trap reset_on_interrupt SIGINT

  if [[ "$DIR" = "$HOMEBREW_REPOSITORY" && -n "$HOMEBREW_UPDATE_TO_TAG" ]]
  then
    UPSTREAM_TAG="$(git tag --list |
                    sort --field-separator=. --key=1,1nr -k 2,2nr -k 3,3nr |
                    grep --max-count=1 '^[0-9]*\.[0-9]*\.[0-9]*$')"
  else
    UPSTREAM_TAG=""
  fi

  if [ -n "$UPSTREAM_TAG" ]
  then
    REMOTE_REF="refs/tags/$UPSTREAM_TAG"
    UPSTREAM_BRANCH="stable"
  else
    REMOTE_REF="origin/$UPSTREAM_BRANCH"
  fi

  if [[ -n "$(git status --untracked-files=all --porcelain 2>/dev/null)" ]]
  then
    if [[ -n "$HOMEBREW_VERBOSE" ]]
    then
      echo "Stashing uncommitted changes to $DIR..."
    fi
    git merge --abort &>/dev/null
    git rebase --abort &>/dev/null
    git reset --mixed "${QUIET_ARGS[@]}"
    if ! git -c "user.email=brew-update@localhost" \
             -c "user.name=brew update" \
             stash save --include-untracked "${QUIET_ARGS[@]}"
    then
      odie <<EOS
Could not 'git stash' in $DIR!
Please stash/commit manually if you need to keep your changes or, if not, run:
  cd $DIR
  git reset --hard origin/master
EOS
    fi
    git reset --hard "${QUIET_ARGS[@]}"
    STASHED="1"
  fi

  INITIAL_BRANCH="$(git symbolic-ref --short HEAD 2>/dev/null)"
  if [[ -n "$UPSTREAM_TAG" ]] ||
     [[ "$INITIAL_BRANCH" != "$UPSTREAM_BRANCH" && -n "$INITIAL_BRANCH" ]]
  then
    # Recreate and check out `#{upstream_branch}` if unable to fast-forward
    # it to `origin/#{@upstream_branch}`. Otherwise, just check it out.
    if [[ -z "$UPSTREAM_TAG" ]] &&
       git merge-base --is-ancestor "$UPSTREAM_BRANCH" "$REMOTE_REF" &>/dev/null
    then
      git checkout --force "$UPSTREAM_BRANCH" "${QUIET_ARGS[@]}"
    else
      git checkout --force -B "$UPSTREAM_BRANCH" "$REMOTE_REF" "${QUIET_ARGS[@]}"
    fi
  fi

  INITIAL_REVISION="$(read_current_revision)"
  export HOMEBREW_UPDATE_BEFORE"$TAP_VAR"="$INITIAL_REVISION"

  # ensure we don't munge line endings on checkout
  git config core.autocrlf false

  if [[ -z "$HOMEBREW_MERGE" ]]
  then
    git rebase "${QUIET_ARGS[@]}" "$REMOTE_REF"
  else
    git merge --no-edit --ff "${QUIET_ARGS[@]}" "$REMOTE_REF" \
      --strategy=recursive \
      --strategy-option=ours \
      --strategy-option=ignore-all-space
  fi

  CURRENT_REVISION="$(read_current_revision)"
  export HOMEBREW_UPDATE_AFTER"$TAP_VAR"="$CURRENT_REVISION"

  if [[ "$INITIAL_REVISION" != "$CURRENT_REVISION" ]]
  then
    HOMEBREW_UPDATED="1"
  fi

  trap '' SIGINT

  if [[ -n "$HOMEBREW_NO_UPDATE_CLEANUP" ]]
  then
    if [[ "$INITIAL_BRANCH" != "$UPSTREAM_BRANCH" && -n "$INITIAL_BRANCH" &&
          ! "$INITIAL_BRANCH" =~ ^v[0-9]+\.[0-9]+\.[0-9]|stable$ ]]
    then
      git checkout "$INITIAL_BRANCH" "${QUIET_ARGS[@]}"
    fi

    pop_stash
  else
    pop_stash_message
  fi

  trap - SIGINT
}

homebrew-update() {
  local option
  local DIR
  local UPSTREAM_BRANCH

  for option in "$@"
  do
    case "$option" in
      -\?|-h|--help|--usage)          brew help update; exit $? ;;
      --verbose)                      HOMEBREW_VERBOSE=1 ;;
      --debug)                        HOMEBREW_DEBUG=1 ;;
      --merge)                        HOMEBREW_MERGE=1 ;;
      --force)                        HOMEBREW_UPDATE_FORCE=1 ;;
      --simulate-from-current-branch) HOMEBREW_SIMULATE_FROM_CURRENT_BRANCH=1 ;;
      --preinstall)                   export HOMEBREW_UPDATE_PREINSTALL=1 ;;
      --*)                            ;;
      -*)
        [[ "$option" = *v* ]] && HOMEBREW_VERBOSE=1
        [[ "$option" = *d* ]] && HOMEBREW_DEBUG=1
        ;;
      *)
        odie <<EOS
This command updates brew itself, and does not take formula names.
Use 'brew upgrade $@' instead.
EOS
        ;;
    esac
  done

  if [[ -n "$HOMEBREW_DEBUG" ]]
  then
    set -x
  fi

  if [[ -z "$HOMEBREW_UPDATE_CLEANUP" && -z "$HOMEBREW_UPDATE_TO_TAG" ]]
  then
    if [[ -n "$HOMEBREW_DEVELOPER" || -n "$HOMEBREW_DEV_CMD_RUN" ]]
    then
      export HOMEBREW_NO_UPDATE_CLEANUP="1"
    else
      export HOMEBREW_UPDATE_TO_TAG="1"
    fi
  fi

  if [[ -z "$HOMEBREW_AUTO_UPDATE_SECS" ]]
  then
    HOMEBREW_AUTO_UPDATE_SECS="60"
  fi

  # check permissions
  if [[ -e "$HOMEBREW_CELLAR" && ! -w "$HOMEBREW_CELLAR" ]]
  then
    odie <<EOS
$HOMEBREW_CELLAR is not writable. You should change the
ownership and permissions of $HOMEBREW_CELLAR back to your
user account:
  sudo chown -R \$(whoami) $HOMEBREW_CELLAR
EOS
  fi

  if [[ ! -w "$HOMEBREW_REPOSITORY" ]]
  then
    odie <<EOS
$HOMEBREW_REPOSITORY is not writable. You should change the
ownership and permissions of $HOMEBREW_REPOSITORY back to your
user account:
  sudo chown -R \$(whoami) $HOMEBREW_REPOSITORY
EOS
  fi

  # we may want to use a Homebrew curl
  if [[ -n "$HOMEBREW_FORCE_BREWED_CURL" &&
      ! -x "$HOMEBREW_PREFIX/opt/curl/bin/curl" ]]
  then
    brew install curl
  fi

  if ! git --version &>/dev/null ||
     [[ -n "$HOMEBREW_FORCE_BREWED_GIT" &&
      ! -x "$HOMEBREW_PREFIX/opt/git/bin/git" ]]
  then
    # we cannot install brewed git if homebrew/core is unavailable.
    [[ -d "$HOMEBREW_LIBRARY/Taps/homebrew/homebrew-core" ]] && brew install git
    unset GIT_EXECUTABLE
    if ! git --version &>/dev/null
    then
      odie "Git must be installed and in your PATH!"
    fi
  fi
  export GIT_TERMINAL_PROMPT="0"
  export GIT_SSH_COMMAND="ssh -oBatchMode=yes"

  if [[ -z "$HOMEBREW_VERBOSE" ]]
  then
    QUIET_ARGS=(-q)
  else
    QUIET_ARGS=()
  fi

  if [[ -z "$HOMEBREW_CURLRC" ]]
  then
    CURL_DISABLE_CURLRC_ARGS=(-q)
  else
    CURL_DISABLE_CURLRC_ARGS=()
  fi

  # only allow one instance of brew update
  lock update

  git_init_if_necessary
  # rename Taps directories
  # this procedure will be removed in the future if it seems unnecessary
  rename_taps_dir_if_necessary

  safe_cd "$HOMEBREW_REPOSITORY"

  # if an older system had a newer curl installed, change each repo's remote URL from GIT to HTTPS
  if [[ -n "$HOMEBREW_SYSTEM_CURL_TOO_OLD" &&
        -x "$HOMEBREW_PREFIX/opt/curl/bin/curl" && 
        "$(git config remote.origin.url)" =~ ^git:// ]]
  then
    git config remote.origin.url "$BREW_OFFICIAL_REMOTE"
    git config -f "$HOMEBREW_LIBRARY/Taps/homebrew/homebrew-core/.git/config" remote.origin.url "$CORE_OFFICIAL_REMOTE"
  fi

  # kill all of subprocess on interrupt
  trap '{ /usr/bin/pkill -P $$; wait; exit 130; }' SIGINT

  local update_failed_file="$HOMEBREW_REPOSITORY/.git/UPDATE_FAILED"
  rm -f "$update_failed_file"

  for DIR in "$HOMEBREW_REPOSITORY" "$HOMEBREW_LIBRARY"/Taps/*/*
  do
    [[ -d "$DIR/.git" ]] || continue
    cd "$DIR" || continue

    if [[ -n "$HOMEBREW_VERBOSE" ]]
    then
      echo "Checking if we need to fetch $DIR..."
    fi

    TAP_VAR="$(repo_var "$DIR")"
    UPSTREAM_BRANCH_DIR="$(upstream_branch)"
    declare UPSTREAM_BRANCH"$TAP_VAR"="$UPSTREAM_BRANCH_DIR"
    declare PREFETCH_REVISION"$TAP_VAR"="$(git rev-parse -q --verify refs/remotes/origin/"$UPSTREAM_BRANCH_DIR")"

    # Force a full update if we don't have any tags.
    if [[ "$DIR" = "$HOMEBREW_REPOSITORY" && -z "$(git tag --list)" ]]
    then
      HOMEBREW_UPDATE_FORCE=1
    fi

    if [[ -z "$HOMEBREW_UPDATE_FORCE" ]]
    then
      [[ -n "$SKIP_FETCH_BREW_REPOSITORY" && "$DIR" = "$HOMEBREW_REPOSITORY" ]] && continue
      [[ -n "$SKIP_FETCH_CORE_REPOSITORY" && "$DIR" = "$HOMEBREW_LIBRARY/Taps/homebrew/homebrew-core" ]] && continue
    fi

    # The upstream repository's default branch may not be master;
    # check refs/remotes/origin/HEAD to see what the default
    # origin branch name is, and use that. If not set, fall back to "master".
    # the refspec ensures that the default upstream branch gets updated
    (
      if [[ -n "$HOMEBREW_UPDATE_PREINSTALL" ]]
      then
        # Skip taps checked/fetched recently
        [[ -n "$(find "$DIR/.git/FETCH_HEAD" -type f -mtime -"${HOMEBREW_AUTO_UPDATE_SECS}"s 2>/dev/null)" ]] && exit
      fi

      UPSTREAM_REPOSITORY_URL="$(git config remote.origin.url)"
      if [[ "$UPSTREAM_REPOSITORY_URL" = "https://github.com/"* ]]
      then
        UPSTREAM_REPOSITORY="${UPSTREAM_REPOSITORY_URL#https://github.com/}"
        UPSTREAM_REPOSITORY="${UPSTREAM_REPOSITORY%.git}"

        if [[ "$DIR" = "$HOMEBREW_REPOSITORY" && -n "$HOMEBREW_UPDATE_TO_TAG" ]]
        then
          # Only try to `git fetch` when the upstream tags have changed
          # (so the API does not return 304: unmodified).
          GITHUB_API_ETAG="$(sed -n 's/^ETag: "\([a-f0-9]\{32\}\)".*/\1/p' ".git/GITHUB_HEADERS" 2>/dev/null)"
          GITHUB_API_ACCEPT="application/vnd.github.v3+json"
          GITHUB_API_ENDPOINT="tags"
        else
          # Only try to `git fetch` when the upstream branch is at a different SHA
          # (so the API does not return 304: unmodified).
          GITHUB_API_ETAG="$(git rev-parse "refs/remotes/origin/$UPSTREAM_BRANCH_DIR")"
          GITHUB_API_ACCEPT="application/vnd.github.v3.sha"
          GITHUB_API_ENDPOINT="commits/$UPSTREAM_BRANCH_DIR"
        fi

        UPSTREAM_SHA_HTTP_CODE="$("$HOMEBREW_CURL" \
           "${CURL_DISABLE_CURLRC_ARGS[@]}" \
           --silent --max-time 3 \
           --location --output /dev/null --write-out "%{http_code}" \
           --dump-header "$DIR/.git/GITHUB_HEADERS" \
           --user-agent "$HOMEBREW_USER_AGENT_CURL" \
           --header "Accept: $GITHUB_API_ACCEPT" \
           --header "If-None-Match: \"$GITHUB_API_ETAG\"" \
           "https://api.github.com/repos/$UPSTREAM_REPOSITORY/$GITHUB_API_ENDPOINT")"

        # Touch FETCH_HEAD to confirm we've checked for an update.
        [[ -f "$DIR/.git/FETCH_HEAD" ]] && touch "$DIR/.git/FETCH_HEAD"
        [[ -z "$HOMEBREW_UPDATE_FORCE" ]] && [[ "$UPSTREAM_SHA_HTTP_CODE" = "304" ]] && exit
      elif [[ -n "$HOMEBREW_UPDATE_PREINSTALL" ]]
      then
        FORCE_AUTO_UPDATE="$(git config homebrew.forceautoupdate 2>/dev/null || echo "false")"
        if [[ "$FORCE_AUTO_UPDATE" != "true" ]]
        then
          # Don't try to do a `git fetch` that may take longer than expected.
          exit
        fi
      fi

      if [[ -n "$HOMEBREW_VERBOSE" ]]
      then
        echo "Fetching $DIR..."
      fi

      if [[ -n "$HOMEBREW_UPDATE_PREINSTALL" ]]
      then
        git fetch --tags --force "${QUIET_ARGS[@]}" origin \
          "refs/heads/$UPSTREAM_BRANCH_DIR:refs/remotes/origin/$UPSTREAM_BRANCH_DIR" 2>/dev/null
      else
        if ! git fetch --tags --force "${QUIET_ARGS[@]}" origin \
          "refs/heads/$UPSTREAM_BRANCH_DIR:refs/remotes/origin/$UPSTREAM_BRANCH_DIR"
        then
          echo "Fetching $DIR failed!" >>"$update_failed_file"
        fi
      fi
    ) &
  done

  wait
  trap - SIGINT

  if [[ -f "$update_failed_file" ]]
  then
    onoe <"$update_failed_file"
    rm -f "$update_failed_file"
    export HOMEBREW_UPDATE_FAILED="1"
  fi

  for DIR in "$HOMEBREW_REPOSITORY" "$HOMEBREW_LIBRARY"/Taps/*/*
  do
    [[ -d "$DIR/.git" ]] || continue
    cd "$DIR" || continue

    TAP_VAR="$(repo_var "$DIR")"
    UPSTREAM_BRANCH_VAR="UPSTREAM_BRANCH$TAP_VAR"
    UPSTREAM_BRANCH="${!UPSTREAM_BRANCH_VAR}"
    CURRENT_REVISION="$(read_current_revision)"

    PREFETCH_REVISION_VAR="PREFETCH_REVISION$TAP_VAR"
    PREFETCH_REVISION="${!PREFETCH_REVISION_VAR}"
    POSTFETCH_REVISION="$(git rev-parse -q --verify refs/remotes/origin/"$UPSTREAM_BRANCH")"

    if [[ -n "$HOMEBREW_SIMULATE_FROM_CURRENT_BRANCH" ]]
    then
      simulate_from_current_branch "$DIR" "$TAP_VAR" "$UPSTREAM_BRANCH" "$CURRENT_REVISION"
    elif [[ -z "$HOMEBREW_UPDATE_FORCE" ]] &&
         [[ "$PREFETCH_REVISION" = "$POSTFETCH_REVISION" ]] &&
         [[ "$CURRENT_REVISION" = "$POSTFETCH_REVISION" ]]
    then
      export HOMEBREW_UPDATE_BEFORE"$TAP_VAR"="$CURRENT_REVISION"
      export HOMEBREW_UPDATE_AFTER"$TAP_VAR"="$CURRENT_REVISION"
    else
      merge_or_rebase "$DIR" "$TAP_VAR" "$UPSTREAM_BRANCH"
      [[ -n "$HOMEBREW_VERBOSE" ]] && echo
    fi
  done

  safe_cd "$HOMEBREW_REPOSITORY"

  if [[ -n "$HOMEBREW_UPDATED" ||
        -n "$HOMEBREW_UPDATE_FAILED" ||
        -n "$HOMEBREW_UPDATE_FORCE" ||
        -d "$HOMEBREW_LIBRARY/LinkedKegs" ||
        (-n "$HOMEBREW_DEVELOPER" && -z "$HOMEBREW_UPDATE_PREINSTALL") ]]
  then
    unset HOMEBREW_RUBY_PATH
    brew update-report "$@"
    return $?
  elif [[ -z "$HOMEBREW_UPDATE_PREINSTALL" ]]
  then
    echo "Already up-to-date."
  fi
}
