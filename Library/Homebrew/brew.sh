HOMEBREW_VERSION="0.9.9"

onoe() {
  if [[ -t 2 ]] # check whether stderr is a tty.
  then
    echo -ne "\033[4;31mError\033[0m: " >&2 # highlight Error with underline and red color
  else
    echo -n "Error: " >&2
  fi
  if [[ $# -eq 0 ]]
  then
    /bin/cat >&2
  else
    echo "$*" >&2
  fi
}

odie() {
  onoe "$@"
  exit 1
}

safe_cd() {
  cd "$@" >/dev/null || odie "Error: failed to cd to $*!"
}

brew() {
  "$HOMEBREW_BREW_FILE" "$@"
}

git() {
  "$HOMEBREW_LIBRARY/Homebrew/shims/scm/git" "$@"
}

# Force UTF-8 to avoid encoding issues for users with broken locale settings.
if [[ "$(locale charmap 2>/dev/null)" != "UTF-8" ]]
then
  export LC_ALL="en_US.UTF-8"
fi

# Where we store built products; a Cellar in HOMEBREW_PREFIX (often /usr/local
# for bottles) unless there's already a Cellar in HOMEBREW_REPOSITORY.
if [[ -d "$HOMEBREW_REPOSITORY/Cellar" ]]
then
  HOMEBREW_CELLAR="$HOMEBREW_REPOSITORY/Cellar"
else
  HOMEBREW_CELLAR="$HOMEBREW_PREFIX/Cellar"
fi

case "$*" in
  --prefix)            echo "$HOMEBREW_PREFIX"; exit 0 ;;
  --cellar)            echo "$HOMEBREW_CELLAR"; exit 0 ;;
  --repository|--repo) echo "$HOMEBREW_REPOSITORY"; exit 0 ;;
esac

if [[ "$HOMEBREW_PREFIX" = "/" || "$HOMEBREW_PREFIX" = "/usr" ]]
then
  # it may work, but I only see pain this route and don't want to support it
  odie "Cowardly refusing to continue at this prefix: $HOMEBREW_PREFIX"
fi

# Users may have these set, pointing the system Ruby
# at non-system gem paths
unset GEM_HOME
unset GEM_PATH

# Users may have this set, injecting arbitrary environment changes into
# bash processes inside builds
unset BASH_ENV

HOMEBREW_SYSTEM="$(uname -s)"
case "$HOMEBREW_SYSTEM" in
  Darwin) HOMEBREW_OSX="1" ;;
  Linux)  HOMEBREW_LINUX="1" ;;
esac

HOMEBREW_CURL="/usr/bin/curl"
if [[ -n "$HOMEBREW_OSX" ]]
then
  HOMEBREW_PROCESSOR="$(uname -p)"
  HOMEBREW_PRODUCT="Homebrew"
  HOMEBREW_SYSTEM="Macintosh"
  # This is i386 even on x86_64 machines
  [[ "$HOMEBREW_PROCESSOR" = "i386" ]] && HOMEBREW_PROCESSOR="Intel"
  HOMEBREW_OSX_VERSION="$(/usr/bin/sw_vers -productVersion)"
  HOMEBREW_OS_VERSION="Mac OS X $HOMEBREW_OSX_VERSION"

  printf -v HOMEBREW_OSX_VERSION_NUMERIC "%02d%02d%02d" ${HOMEBREW_OSX_VERSION//./ }
  if [[ "$HOMEBREW_OSX_VERSION_NUMERIC" -lt "100900" &&
        -x "$HOMEBREW_PREFIX/opt/curl/bin/curl" ]]
  then
    HOMEBREW_CURL="$HOMEBREW_PREFIX/opt/curl/bin/curl"
  fi
else
  HOMEBREW_PROCESSOR="$(uname -m)"
  HOMEBREW_PRODUCT="${HOMEBREW_SYSTEM}brew"
  HOMEBREW_OSX_VERSION=0
  [[ -n "$HOMEBREW_LINUX" ]] && HOMEBREW_OS_VERSION="$(lsb_release -sd 2>/dev/null)"
  : "${HOMEBREW_OS_VERSION:=$(uname -r)}"
fi
HOMEBREW_USER_AGENT="$HOMEBREW_PRODUCT/$HOMEBREW_VERSION ($HOMEBREW_SYSTEM; $HOMEBREW_PROCESSOR $HOMEBREW_OS_VERSION)"
HOMEBREW_CURL_VERSION="$("$HOMEBREW_CURL" --version 2>/dev/null | head -n1 | /usr/bin/awk '{print $1"/"$2}')"
HOMEBREW_USER_AGENT_CURL="$HOMEBREW_USER_AGENT $HOMEBREW_CURL_VERSION"

if [[ -z "$HOMEBREW_CACHE" ]]
then
  if [[ -n "$HOMEBREW_OSX" ]]
  then
    HOMEBREW_CACHE="$HOME/Library/Caches/Homebrew"
  else
    HOMEBREW_CACHE="$HOME/.cache/Homebrew"
  fi
fi

# Declared in bin/brew
export HOMEBREW_BREW_FILE
export HOMEBREW_PREFIX
export HOMEBREW_REPOSITORY
export HOMEBREW_LIBRARY

# Declared in brew.sh
export HOMEBREW_VERSION
export HOMEBREW_CACHE
export HOMEBREW_CELLAR
export HOMEBREW_SYSTEM
export HOMEBREW_CURL
export HOMEBREW_PROCESSOR
export HOMEBREW_PRODUCT
export HOMEBREW_OS_VERSION
export HOMEBREW_OSX_VERSION
export HOMEBREW_USER_AGENT
export HOMEBREW_USER_AGENT_CURL

if [[ -n "$HOMEBREW_OSX" ]]
then
  XCODE_SELECT_PATH=$('/usr/bin/xcode-select' --print-path 2>/dev/null)
  if [[ "$XCODE_SELECT_PATH" = "/" ]]
  then
    odie <<EOS
Your xcode-select path is currently set to '/'.
This causes the 'xcrun' tool to hang, and can render Homebrew unusable.
If you are using Xcode, you should:
  sudo xcode-select -switch /Applications/Xcode.app
Otherwise, you should:
  sudo rm -rf /usr/share/xcode-select
EOS
  fi

  # Don't check xcrun if Xcode and the CLT aren't installed, as that opens
  # a popup window asking the user to install the CLT
  if [[ -n "$XCODE_SELECT_PATH" ]]
  then
    XCRUN_OUTPUT="$(/usr/bin/xcrun clang 2>&1)"
    XCRUN_STATUS="$?"

    if [[ "$XCRUN_STATUS" -ne 0 && "$XCRUN_OUTPUT" = *license* ]]
    then
      odie <<EOS
You have not agreed to the Xcode license. Please resolve this by running:
  sudo xcodebuild -license
EOS
    fi
  fi
fi

# Many Pathname operations use getwd when they shouldn't, and then throw
# odd exceptions. Reduce our support burden by showing a user-friendly error.
if [[ ! -d "$(pwd)" ]]
then
  odie "The current working directory doesn't exist, cannot proceed."
fi

# At present, we always want to build from source on Linux
if [[ -n "$HOMEBREW_LINUX" ]]
then
  export HOMEBREW_BUILD_FROM_SOURCE=1
fi

if [[ "$1" = -v ]]
then
  # Shift the -v to the end of the parameter list
  shift
  set -- "$@" -v
fi

HOMEBREW_ARG_COUNT="$#"
HOMEBREW_COMMAND="$1"
shift
case "$HOMEBREW_COMMAND" in
  ls)          HOMEBREW_COMMAND="list" ;;
  homepage)    HOMEBREW_COMMAND="home" ;;
  -S)          HOMEBREW_COMMAND="search" ;;
  up)          HOMEBREW_COMMAND="update" ;;
  ln)          HOMEBREW_COMMAND="link" ;;
  instal)      HOMEBREW_COMMAND="install" ;; # gem does the same
  rm)          HOMEBREW_COMMAND="uninstall" ;;
  remove)      HOMEBREW_COMMAND="uninstall" ;;
  configure)   HOMEBREW_COMMAND="diy" ;;
  abv)         HOMEBREW_COMMAND="info" ;;
  dr)          HOMEBREW_COMMAND="doctor" ;;
  --repo)      HOMEBREW_COMMAND="--repository" ;;
  environment) HOMEBREW_COMMAND="--env" ;;
  --config)    HOMEBREW_COMMAND="config" ;;
esac

if [[ -f "$HOMEBREW_LIBRARY/Homebrew/cmd/$HOMEBREW_COMMAND.sh" ]]
then
  HOMEBREW_BASH_COMMAND="$HOMEBREW_LIBRARY/Homebrew/cmd/$HOMEBREW_COMMAND.sh"
elif [[ -n "$HOMEBREW_DEVELOPER" && -f "$HOMEBREW_LIBRARY/Homebrew/dev-cmd/$HOMEBREW_COMMAND.sh" ]]
then
  HOMEBREW_BASH_COMMAND="$HOMEBREW_LIBRARY/Homebrew/dev-cmd/$HOMEBREW_COMMAND.sh"
fi

check-run-command-as-root() {
  [[ "$(id -u)" = 0 ]] || return
  export HOMEBREW_NO_SANDBOX="1"

  [[ "$HOMEBREW_COMMAND" = "services" ]] && return

  onoe <<EOS
Running Homebrew as root is extremely dangerous. As Homebrew does not
drop privileges on installation you are giving all build scripts full access
to your system. As a result of the OS X sandbox not handling the root user
correctly HOMEBREW_NO_SANDBOX has been set so the sandbox will not be used. If
we have not merged a pull request to add privilege dropping by November 1st
2016 running Homebrew as root will be disabled. No Homebrew maintainers plan
to work on this functionality.
EOS

  case "$HOMEBREW_COMMAND" in
    analytics|create|install|link|migrate|pin|postinstall|reinstall|switch|tap|\
    tap-pin|update|upgrade|vendor-install)
      ;;
    *)
      return
      ;;
  esac

  local brew_file_ls_info=($(ls -nd "$HOMEBREW_BREW_FILE"))
  if [[ "${brew_file_ls_info[2]}" != 0 ]]
  then
    odie <<EOS
Cowardly refusing to 'sudo brew $HOMEBREW_COMMAND'
You can use brew with sudo, but only if the brew executable is owned by root.
However, this is both not recommended and completely unsupported so do so at
your own risk.
EOS
  fi
}
check-run-command-as-root

# Disable analytics
export HOMEBREW_NO_ANALYTICS=1
# Hide shellcheck complaint:
# shellcheck source=/dev/null
source "$HOMEBREW_LIBRARY/Homebrew/utils/analytics.sh"
setup-analytics
report-analytics-screenview-command

update-preinstall() {
  [[ -z "$HOMEBREW_NO_AUTO_UPDATE" ]] || return
  [[ -z "$HOMEBREW_UPDATE_PREINSTALL" ]] || return

  if [[ "$HOMEBREW_COMMAND" = "install" || "$HOMEBREW_COMMAND" = "upgrade" ]]
  then
    brew update --preinstall
  fi

  # If we've checked for updates, we don't need to check again.
  export HOMEBREW_NO_AUTO_UPDATE="1"
}

if [[ -n "$HOMEBREW_BASH_COMMAND" ]]
then
  # source rather than executing directly to ensure the entire file is read into
  # memory before it is run. This makes running a Bash script behave more like
  # a Ruby script and avoids hard-to-debug issues if the Bash script is updated
  # at the same time as being run.
  #
  # Hide shellcheck complaint:
  # shellcheck source=/dev/null
  source "$HOMEBREW_BASH_COMMAND"
  { update-preinstall; "homebrew-$HOMEBREW_COMMAND" "$@"; exit $?; }
else
  # Hide shellcheck complaint:
  # shellcheck source=/dev/null
  source "$HOMEBREW_LIBRARY/Homebrew/utils/ruby.sh"
  setup-ruby-path

  # Unshift command back into argument list (unless argument list was empty).
  [[ "$HOMEBREW_ARG_COUNT" -gt 0 ]] && set -- "$HOMEBREW_COMMAND" "$@"
  { update-preinstall; exec "$HOMEBREW_RUBY_PATH" -W0 "$HOMEBREW_LIBRARY/Homebrew/brew.rb" "$@"; }
fi
