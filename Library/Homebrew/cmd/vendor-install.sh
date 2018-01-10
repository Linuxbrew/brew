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
    ruby_URL="https://homebrew.bintray.com/bottles-portable/portable-ruby-2.3.3.leopard_64.bottle.1.tar.gz"
    ruby_SHA="34ce9e4c9c1be28db564d744165aa29291426f8a3d2ef806ba4f0b9175aedb2b"
  else
    ruby_URL=""
    ruby_SHA=""
  fi
elif [[ -n "$HOMEBREW_LINUX" ]]
then
  case "$HOMEBREW_PROCESSOR" in
    armv7l)
      ruby_URL="https://homebrew.bintray.com/bottles-portable/portable-ruby-2.3.3.armv7l_linux.bottle.1.tar.gz"
      ruby_SHA="d26affe6f6ac299557a9044b311b4066b554874fc828ebc323d2705d3f4a8249"
      ;;
    x86_64)
      ruby_URL="https://homebrew.bintray.com/bottles-portable/portable-ruby-2.3.3.x86_64_linux.bottle.1.tar.gz"
      ruby_SHA="33643b1ca6f860d6df01686636326785763e5e81cf0cef37d8a7ab96a6ca1fa1"
      ;;
  esac
fi

# Execute the specified command, and suppress stderr unless HOMEBREW_STDERR is set.
quiet_stderr() {
  if [[ -z "$HOMEBREW_STDERR" ]]; then
    command "$@" 2>/dev/null
  else
    command "$@"
  fi
}

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
    curl_args[${#curl_args[*]}]="--silent"
  elif [[ -z "$HOMEBREW_VERBOSE" ]]
  then
    curl_args[${#curl_args[*]}]="--progress-bar"
  fi

  if [[ "$HOMEBREW_MACOS_VERSION_NUMERIC" -lt "100600" ]]
  then
    curl_args[${#curl_args[*]}]="--insecure"
  fi

  temporary_path="$CACHED_LOCATION.incomplete"

  mkdir -p "$HOMEBREW_CACHE"
  [[ -n "$HOMEBREW_QUIET" ]] || echo "==> Downloading $VENDOR_URL" >&2
  if [[ -f "$CACHED_LOCATION" ]]
  then
    [[ -n "$HOMEBREW_QUIET" ]] || echo "Already downloaded: $CACHED_LOCATION" >&2
  else
    if [[ -f "$temporary_path" ]]
    then
      "$HOMEBREW_CURL" "${curl_args[@]}" -C - "$VENDOR_URL" -o "$temporary_path"
      if [[ $? -eq 33 ]]
      then
        [[ -n "$HOMEBREW_QUIET" ]] || echo "Trying a full download" >&2
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

  if [[ -x "/usr/bin/shasum" ]]
  then
    sha="$(/usr/bin/shasum -a 256 "$CACHED_LOCATION" | cut -d' ' -f1)"
  elif [[ -x "$(which sha256sum)" ]]
  then
    sha="$(sha256sum "$CACHED_LOCATION" | cut -d' ' -f1)"
  elif [[ -x "$(which ruby)" ]]
  then
    sha="$(ruby <<EOSCRIPT
            require 'digest/sha2'
            digest = Digest::SHA256.new
            File.open('$CACHED_LOCATION', 'rb') { |f| digest.update(f.read) }
            puts digest.hexdigest
EOSCRIPT
)"
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
  [[ -n "$HOMEBREW_QUIET" ]] || echo "==> Pouring $(basename "$VENDOR_URL")" >&2
  tar "$tar_args" "$CACHED_LOCATION"
  safe_cd "$VENDOR_DIR/portable-$VENDOR_NAME"

  if quiet_stderr "./$VENDOR_VERSION/bin/$VENDOR_NAME" --version >/dev/null
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
