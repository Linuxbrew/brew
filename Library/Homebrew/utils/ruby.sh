setup-ruby-path() {
  local vendor_dir
  local vendor_ruby_current_version
  local vendor_ruby_path
  local ruby_version_new_enough
  local minimum_ruby_version="2.3.7"

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
        if ! brew vendor-install ruby
        then
          onoe "Failed to upgrade vendor Ruby."
        fi
      fi
    else
      if [[ -n "$HOMEBREW_MACOS" ]]
      then
        HOMEBREW_RUBY_PATH="/System/Library/Frameworks/Ruby.framework/Versions/Current/usr/bin/ruby"
      else
        HOMEBREW_RUBY_PATH="$(type -P ruby)"
      fi

      if [[ -n "$HOMEBREW_RUBY_PATH" && -z "$HOMEBREW_FORCE_VENDOR_RUBY" ]]
      then
        ruby_version_new_enough="$("$HOMEBREW_RUBY_PATH" -rrubygems -e "puts Gem::Version.new(RUBY_VERSION.to_s.dup) >= Gem::Version.new('$minimum_ruby_version')")"
      fi

      if [[ -z "$HOMEBREW_RUBY_PATH" || -n "$HOMEBREW_FORCE_VENDOR_RUBY" || "$ruby_version_new_enough" != "true" ]]
      then
        brew vendor-install ruby
        if [[ ! -x "$vendor_ruby_path" ]]
        then
          odie "Failed to install vendor Ruby."
        fi
        rm -rf "$vendor_dir/bundle/ruby"
        HOMEBREW_RUBY_PATH="$vendor_ruby_path"
      fi
    fi
  fi

  export HOMEBREW_RUBY_PATH
}
