#: @hide_from_man_page
#:  * `vendor-install` [<target>]:
#:     Install vendor version of Homebrew dependencies.

# Hide shellcheck complaint:
# shellcheck source=/dev/null
source "$HOMEBREW_LIBRARY/Homebrew/utils/lock.sh"

VENDOR_DIR="$HOMEBREW_LIBRARY/Homebrew/vendor"

# Built from https://github.com/Homebrew/homebrew-portable.
if [[ -n "$HOMEBREW_MACOS" ]]
then
  if [[ "$HOMEBREW_PROCESSOR" = "Intel" ]]
  then
    ruby_URL="https://homebrew.bintray.com/bottles-portable/portable-ruby-2.0.0-p648.leopard_64.bottle.tar.gz"
    ruby_SHA="5c1240abe4be91c9774a0089c2a38a8ccfff87c009e8e5786730c659d5e633f7"
  else
    ruby_URL=""
    ruby_SHA=""
  fi
elif [[ -n "$HOMEBREW_LINUX" ]]
then
  ruby_URL="https://homebrew.bintray.com/bottles-portable/portable-ruby-2.0.0-p648.x86_64_linux.bottle.tar.gz"
  ruby_SHA="dbb5118a22a6a75cc77e62544a3d8786d383fab1bdaf8c154951268807357bf0"
fi

fetch() {
  local -a curl_args
  local sha
  local temporary_path

  curl_args=(
    --fail
    --remote-time
    --location
    --user-agent "$HOMEBREW_USER_AGENT_CURL"
  )

  if [[ -n "$HOMEBREW_QUIET" ]]
  then
    curl_args+=(--silent)
  elif [[ -z "$HOMEBREW_VERBOSE" ]]
  then
    curl_args+=(--progress-bar)
  fi

  temporary_path="$CACHED_LOCATION.incomplete"

  mkdir -p "$HOMEBREW_CACHE"
  [[ -n "$HOMEBREW_QUIET" ]] || echo "==> Downloading $VENDOR_URL"
  if [[ -f "$CACHED_LOCATION" ]]
  then
    [[ -n "$HOMEBREW_QUIET" ]] || echo "Already downloaded: $CACHED_LOCATION"
  else
    if [[ -f "$temporary_path" ]]
    then
      "$HOMEBREW_CURL" "${curl_args[@]}" -C - "$VENDOR_URL" -o "$temporary_path"
      if [[ $? -eq 33 ]]
      then
        [[ -n "$HOMEBREW_QUIET" ]] || echo "Trying a full download"
        rm -f "$temporary_path"
        "$HOMEBREW_CURL" "${curl_args[@]}" "$VENDOR_URL" -o "$temporary_path"
      fi
    else
      "$HOMEBREW_CURL" "${curl_args[@]}" "$VENDOR_URL" -o "$temporary_path"
    fi

    if [[ ! -f "$temporary_path" ]]
    then
      odie "Download failed: $VENDOR_URL"
    fi

    trap '' SIGINT
    mv "$temporary_path" "$CACHED_LOCATION"
    trap - SIGINT
  fi

  if [[ -n "$(which shasum)" ]]
  then
    sha="$(shasum -a 256 "$CACHED_LOCATION" | cut -d' ' -f1)"
  elif [[ -n "$(which sha256sum)" ]]
  then
    sha="$(sha256sum "$CACHED_LOCATION" | cut -d' ' -f1)"
  else
    odie "Cannot verify the checksum ('shasum' or 'sha256sum' not found)!"
  fi

  if [[ "$sha" != "$VENDOR_SHA" ]]
  then
    odie <<EOS
Checksum mismatch.
Expected: $VENDOR_SHA
Actual: $sha
Archive: $CACHED_LOCATION
To retry an incomplete download, remove the file above.
EOS
  fi
}

install() {
  local tar_args
  local verb

  if [[ -n "$HOMEBREW_VERBOSE" ]]
  then
    tar_args="xvzf"
  else
    tar_args="xzf"
  fi

  mkdir -p "$VENDOR_DIR/portable-$VENDOR_NAME"
  safe_cd "$VENDOR_DIR/portable-$VENDOR_NAME"

  trap '' SIGINT

  if [[ -d "$VENDOR_VERSION" ]]
  then
    verb="reinstall"
    mv "$VENDOR_VERSION" "$VENDOR_VERSION.reinstall"
  elif [[ -n "$(ls -A .)" ]]
  then
    verb="upgrade"
  else
    verb="install"
  fi

  safe_cd "$VENDOR_DIR"
  [[ -n "$HOMEBREW_QUIET" ]] || echo "==> Unpacking $(basename "$VENDOR_URL")"
  tar "$tar_args" "$CACHED_LOCATION"
  safe_cd "$VENDOR_DIR/portable-$VENDOR_NAME"

  if "./$VENDOR_VERSION/bin/$VENDOR_NAME" --version >/dev/null 2>&1
  then
    ln -sfn "$VENDOR_VERSION" current
    # remove old vendor installations by sorting files with modified time.
    ls -t | grep -Ev "^(current|$VENDOR_VERSION)" | tail -n +4 | xargs rm -rf
    if [[ -d "$VENDOR_VERSION.reinstall" ]]
    then
      rm -rf "$VENDOR_VERSION.reinstall"
    fi
  else
    rm -rf "$VENDOR_VERSION"
    if [[ -d "$VENDOR_VERSION.reinstall" ]]
    then
      mv "$VENDOR_VERSION.reinstall" "$VENDOR_VERSION"
    fi
    odie "Failed to $verb vendor $VENDOR_NAME."
  fi

  trap - SIGINT
}

homebrew-vendor-install() {
  local option
  local url_var
  local sha_var

  for option in "$@"
  do
    case "$option" in
      -\?|-h|--help|--usage) brew help vendor-install; exit $? ;;
      --verbose)             HOMEBREW_VERBOSE=1 ;;
      --quiet)               HOMEBREW_QUIET=1 ;;
      --debug)               HOMEBREW_DEBUG=1 ;;
      --*)                   ;;
      -*)
        [[ "$option" = *v* ]] && HOMEBREW_VERBOSE=1
        [[ "$option" = *q* ]] && HOMEBREW_QUIET=1
        [[ "$option" = *d* ]] && HOMEBREW_DEBUG=1
        ;;
      *)
        [[ -n "$VENDOR_NAME" ]] && odie "This command does not take multiple vendor targets"
        VENDOR_NAME="$option"
        ;;
    esac
  done

  [[ -z "$VENDOR_NAME" ]] && odie "This command requires one vendor target."
  [[ -n "$HOMEBREW_DEBUG" ]] && set -x

  url_var="${VENDOR_NAME}_URL"
  sha_var="${VENDOR_NAME}_SHA"
  VENDOR_URL="${!url_var}"
  VENDOR_SHA="${!sha_var}"

  if [[ -z "$VENDOR_URL" || -z "$VENDOR_SHA" ]]
  then
    odie <<-EOS
Cannot find a vendored version of $VENDOR_NAME for your $HOMEBREW_PROCESSOR
processor on $HOMEBREW_PRODUCT!
EOS
  fi

  VENDOR_VERSION="$(<"$VENDOR_DIR/portable-$VENDOR_NAME-version")"
  CACHED_LOCATION="$HOMEBREW_CACHE/$(basename "$VENDOR_URL")"

  lock "vendor-install-$VENDOR_NAME"
  fetch
  install
}
