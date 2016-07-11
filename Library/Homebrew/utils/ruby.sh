original-setup-ruby-path() {
  if [[ -z "$HOMEBREW_DEVELOPER" ]]
  then
    unset HOMEBREW_RUBY_PATH
  fi

  if [[ -z "$HOMEBREW_RUBY_PATH" ]]
  then
    if [[ -n "$HOMEBREW_OSX" ]]
    then
      HOMEBREW_RUBY_PATH="/System/Library/Frameworks/Ruby.framework/Versions/Current/usr/bin/ruby"
    else
      HOMEBREW_RUBY_PATH="$(which ruby)"
      if [[ -z "$HOMEBREW_RUBY_PATH" ]]
      then
        odie "No Ruby found, cannot proceed."
      fi
    fi
  fi

  export HOMEBREW_RUBY_PATH
}

setup-ruby-path() {
  if [[ -z "$HOMEBREW_USE_VENDOR_RUBY" ]]
  then
    original-setup-ruby-path
    return
  fi

  local vendor_dir
  local vendor_ruby_current_version
  local vendor_ruby_path
  local ruby_version_major

  vendor_dir="$HOMEBREW_LIBRARY/Homebrew/vendor"
  vendor_ruby_current_version="$vendor_dir/portable-ruby/current"
  vendor_ruby_path="$vendor_ruby_current_version/bin/ruby"

  if [[ -z "$HOMEBREW_DEVELOPER" ]]
  then
    unset HOMEBREW_RUBY_PATH
  fi

  if [[ -z "$HOMEBREW_RUBY_PATH" && "$HOMEBREW_COMMAND" != "vendor-install" ]]
  then
    if [[ -x "$vendor_ruby_path" ]]
    then
      HOMEBREW_RUBY_PATH="$vendor_ruby_path"

      if [[ $(readlink "$vendor_ruby_current_version") != "$(<"$vendor_dir/portable-ruby-version")" ]]
      then
        if ! brew vendor-install ruby --quiet
        then
          onoe "Failed to upgrade vendor Ruby."
        fi
      fi
    else
      if [[ -n "$HOMEBREW_OSX" ]]
      then
        HOMEBREW_RUBY_PATH="/System/Library/Frameworks/Ruby.framework/Versions/Current/usr/bin/ruby"
      else
        HOMEBREW_RUBY_PATH="$(which ruby)"
      fi

      if [[ -n "$HOMEBREW_RUBY_PATH" ]]
      then
        ruby_version_major="$("$HOMEBREW_RUBY_PATH" --version)"
        ruby_version_major="${ruby_version_major#ruby }"
        ruby_version_major="${ruby_version_major%%.*}"
      fi

      if [[ "$ruby_version_major" != "2" ]]
      then
        brew vendor-install ruby --quiet
        if [[ ! -x "$vendor_ruby_path" ]]
        then
          odie "Failed to install vendor Ruby."
        fi
        HOMEBREW_RUBY_PATH="$vendor_ruby_path"
      fi
    fi
  fi

  export HOMEBREW_RUBY_PATH
}
