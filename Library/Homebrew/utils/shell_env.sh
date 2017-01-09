#!/bin/bash
set +o posix

IFS="="

while read -r key value
do
  export "$key=$value"
done < /tmp/homebrew-env

# Need to reset IFS to default value for later shell functions like 'printf -v HOMEBREW_MACOS_VERSION_NUMERIC ...' to work
unset IFS

# HOMEBREW_LIBRARY will have been readded above having been added originally in 'bin/brew'
source "$HOMEBREW_LIBRARY/Homebrew/brew.sh"
