# create a lock using `flock(2)`. A name is required as first argument.
# the lock will be automatically unlocked when the shell process quits.
# Noted due to the fixed FD, a shell process can only create one lock.
lock() {
  local name="$1"
  local lock_dir="$HOMEBREW_PREFIX/var/homebrew/locks"
  local lock_file="$lock_dir/$name"
  [[ -d "$lock_dir" ]] || mkdir -p "$lock_dir"
  # 200 is the file descriptor used in the lock.
  # This FD should be used exclusively for lock purpose.
  # Any value except 0(stdin), 1(stdout) and 2(stderr) can do the job.
  # Noted, FD is unique per process but it will be shared to subprocess.
  # It is recommended to choose a large number to avoid conflicting with
  # other FD opened by the script.
  #
  # close FD first, this is required if parent process holds a different lock.
  exec 200>&-
  # open the lock file to FD, so the shell process can hold the lock.
  exec 200>"$lock_file"
  if ! _create_lock 200
  then
    odie <<EOS
Another active Homebrew process is already in progress.
Please wait for it to finish or terminate it to continue.
EOS
  fi
}

_create_lock() {
  local lock_fd="$1"
  local ruby="/usr/bin/ruby"
  [[ -x "$ruby" ]] || ruby="$(which ruby 2>/dev/null)"

  if [[ -n "$ruby" ]]
  then
    "$ruby" -e "File.new($lock_fd).flock(File::LOCK_EX | File::LOCK_NB) || exit(1)"
  elif [[ -n "$(which flock)" ]]
  then
    flock -n "$lock_fd"
  else
    onoe "Cannot create lock, please avoid running brew in parallel."
  fi
}
