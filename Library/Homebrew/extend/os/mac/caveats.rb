class Caveats
  undef plist_caveats

  def plist_caveats
    s = []
    if f.plist || (keg&.plist_installed?)
      plist_domain = f.plist_path.basename(".plist")

      # we readlink because this path probably doesn't exist since caveats
      # occurs before the link step of installation
      # Yosemite security measures mildly tighter rules:
      # https://github.com/Homebrew/legacy-homebrew/issues/33815
      if !plist_path.file? || !plist_path.symlink?
        if f.plist_startup
          s << "To have launchd start #{f.full_name} now and restart at startup:"
          s << "  sudo brew services start #{f.full_name}"
        else
          s << "To have launchd start #{f.full_name} now and restart at login:"
          s << "  brew services start #{f.full_name}"
        end
      # For startup plists, we cannot tell whether it's running on launchd,
      # as it requires for `sudo launchctl list` to get real result.
      elsif f.plist_startup
        s << "To restart #{f.full_name} after an upgrade:"
        s << "  sudo brew services restart #{f.full_name}"
      elsif Kernel.system "/bin/launchctl list #{plist_domain} &>/dev/null"
        s << "To restart #{f.full_name} after an upgrade:"
        s << "  brew services restart #{f.full_name}"
      else
        s << "To start #{f.full_name}:"
        s << "  brew services start #{f.full_name}"
      end

      if f.plist_manual
        s << "Or, if you don't want/need a background service you can just run:"
        s << "  #{f.plist_manual}"
      end

      # pbpaste is the system clipboard tool on macOS and fails with `tmux` by default
      # check if this is being run under `tmux` to avoid failing
      if ENV["TMUX"] && !quiet_system("/usr/bin/pbpaste")
        s << "" << "WARNING: brew services will fail when run under tmux."
      end
    end
    s.join("\n") + "\n" unless s.empty?
  end
end
