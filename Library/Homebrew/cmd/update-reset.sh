#:  * `update-reset`:
#:    Fetches and resets Homebrew and all tap repositories using `git`(1) to
#:    their latest `origin/master`. Note this will destroy all your uncommitted
#:    or committed changes.

homebrew-update-reset() {
  local DIR

  for option in "$@"
  do
    case "$option" in
      -\?|-h|--help|--usage)          brew help update-reset; exit $? ;;
      --debug)                        HOMEBREW_DEBUG=1 ;;
      -*)
        [[ "$option" = *d* ]] && HOMEBREW_DEBUG=1
        ;;
      *)
        odie <<EOS
This command updates brew itself, and does not take formula names.
Use 'brew upgrade <formula>'.
EOS
        ;;
    esac
  done

  if [[ -n "$HOMEBREW_DEBUG" ]]
  then
    set -x
  fi

  for DIR in "$HOMEBREW_REPOSITORY" "$HOMEBREW_LIBRARY"/Taps/*/*
  do
    [[ -d "$DIR/.git" ]] || continue
    cd "$DIR" || continue
    echo "==> Fetching $DIR..."

    if [[ "$DIR" = "$HOMEBREW_REPOSITORY" ]]; then
      latest_tag="$(git ls-remote --tags --refs -q origin | tail -n1 | cut -f2)"
      git fetch --force origin --shallow-since="$latest_tag"
    else
      git fetch --force --tags origin
    fi

    echo

    echo "==> Resetting $DIR..."
    git checkout --force -B master origin/master
    echo
  done
}
