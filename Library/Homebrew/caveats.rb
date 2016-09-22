class Caveats
  attr_reader :f

  def initialize(f)
    @f = f
  end

  def caveats
    caveats = []
    begin
      build = f.build
      f.build = Tab.for_formula(f)
      s = f.caveats.to_s
      caveats << s.chomp + "\n" unless s.empty?
    ensure
      f.build = build
    end
    caveats << keg_only_text
    caveats << bash_completion_caveats
    caveats << zsh_completion_caveats
    caveats << fish_completion_caveats
    caveats << plist_caveats
    caveats << python_caveats
    caveats << app_caveats
    caveats << elisp_caveats
    caveats.compact.join("\n")
  end

  def empty?
    caveats.empty?
  end

  private

  def keg
    @keg ||= [f.prefix, f.opt_prefix, f.linked_keg].map do |d|
      begin
        Keg.new(d.resolved_path)
      rescue
        nil
      end
    end.compact.first
  end

  def keg_only_text
    return unless f.keg_only?

    s = "This formula is keg-only, which means it was not symlinked into #{HOMEBREW_PREFIX}."
    s << "\n\n#{f.keg_only_reason}"
    if f.lib.directory? || f.include.directory?
      s <<
        <<-EOS.undent_________________________________________________________72


        Generally there are no consequences of this for you. If you build your
        own software and it requires this formula, you'll need to add to your
        build variables:

        EOS
      s << "    LDFLAGS:  -L#{f.opt_lib}\n" if f.lib.directory?
      s << "    CPPFLAGS: -I#{f.opt_include}\n" if f.include.directory?

      if which("pkg-config")
        s << "    PKG_CONFIG_PATH: #{f.opt_lib}/pkgconfig\n" if (f.lib/"pkgconfig").directory?
        s << "    PKG_CONFIG_PATH: #{f.opt_share}/pkgconfig\n" if (f.share/"pkgconfig").directory?
      end
    end
    s << "\n"
  end

  def bash_completion_caveats
    return unless keg
    return unless keg.completion_installed?(:bash)

    <<-EOS.undent
      Bash completion has been installed to:
        #{HOMEBREW_PREFIX}/etc/bash_completion.d
    EOS
  end

  def zsh_completion_caveats
    return unless keg
    return unless keg.completion_installed?(:zsh)

    <<-EOS.undent
      zsh completion has been installed to:
        #{HOMEBREW_PREFIX}/share/zsh/site-functions
    EOS
  end

  def fish_completion_caveats
    return unless keg
    return unless keg.completion_installed?(:fish)
    return unless which("fish")

    <<-EOS.undent
      fish completion has been installed to:
        #{HOMEBREW_PREFIX}/share/fish/vendor_completions.d
    EOS
  end

  def python_caveats
    return unless keg
    return unless keg.python_site_packages_installed?

    s = nil
    homebrew_site_packages = Language::Python.homebrew_site_packages
    user_site_packages = Language::Python.user_site_packages "python"
    pth_file = user_site_packages/"homebrew.pth"
    instructions = <<-EOS.undent.gsub(/^/, "  ")
      mkdir -p #{user_site_packages}
      echo 'import site; site.addsitedir("#{homebrew_site_packages}")' >> #{pth_file}
    EOS

    if f.keg_only?
      keg_site_packages = f.opt_prefix/"lib/python2.7/site-packages"
      unless Language::Python.in_sys_path?("python", keg_site_packages)
        s = <<-EOS.undent
          If you need Python to find bindings for this keg-only formula, run:
            echo #{keg_site_packages} >> #{homebrew_site_packages/f.name}.pth
        EOS
        s += instructions unless Language::Python.reads_brewed_pth_files?("python")
      end
      return s
    end

    return if Language::Python.reads_brewed_pth_files?("python")

    if !Language::Python.in_sys_path?("python", homebrew_site_packages)
      s = <<-EOS.undent
        Python modules have been installed and Homebrew's site-packages is not
        in your Python sys.path, so you will not be able to import the modules
        this formula installed. If you plan to develop with these modules,
        please run:
      EOS
      s += instructions
    elsif keg.python_pth_files_installed?
      s = <<-EOS.undent
        This formula installed .pth files to Homebrew's site-packages and your
        Python isn't configured to process them, so you will not be able to
        import the modules this formula installed. If you plan to develop
        with these modules, please run:
      EOS
      s += instructions
    end
    s
  end

  def app_caveats
    return unless keg
    return unless keg.app_installed?

    <<-EOS.undent
      .app bundles were installed.
      Run `brew linkapps #{keg.name}` to symlink these to /Applications.
    EOS
  end

  def elisp_caveats
    return if f.keg_only?
    return unless keg
    return unless keg.elisp_installed?

    <<-EOS.undent
      Emacs Lisp files have been installed to:
        #{HOMEBREW_PREFIX}/share/emacs/site-lisp/#{f.name}
    EOS
  end

  def plist_caveats
    s = []
    if f.plist || (keg && keg.plist_installed?)
      destination = if f.plist_startup
        "/Library/LaunchDaemons"
      else
        "~/Library/LaunchAgents"
      end

      plist_filename = if f.plist
        f.plist_path.basename
      else
        File.basename Dir["#{keg}/*.plist"].first
      end
      plist_domain = f.plist_path.basename(".plist")
      destination_path = Pathname.new File.expand_path destination
      plist_path = destination_path/plist_filename

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

      if ENV["TMUX"] && !quiet_system("/usr/bin/pbpaste")
        s << "" << "WARNING: brew services will fail when run under tmux."
      end
    end
    s.join("\n") + "\n" unless s.empty?
  end
end
