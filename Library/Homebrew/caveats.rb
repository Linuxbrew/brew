require "forwardable"
require "language/python"

class Caveats
  extend Forwardable

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
    caveats << function_completion_caveats(:bash)
    caveats << function_completion_caveats(:zsh)
    caveats << function_completion_caveats(:fish)
    caveats << plist_caveats
    caveats << python_caveats
    caveats << elisp_caveats
    caveats.compact.join("\n")
  end

  delegate [:empty?, :to_s] => :caveats

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

    s = <<~EOS
      This formula is keg-only, which means it was not symlinked into #{HOMEBREW_PREFIX},
      because #{f.keg_only_reason.to_s.chomp}.
    EOS
    if f.bin.directory? || f.sbin.directory?
      s << "\nIf you need to have this software first in your PATH run:\n"
      if f.bin.directory?
        s << "  #{Utils::Shell.prepend_path_in_profile(f.opt_bin.to_s)}\n"
      end
      if f.sbin.directory?
        s << "  #{Utils::Shell.prepend_path_in_profile(f.opt_sbin.to_s)}\n"
      end
    end

    if f.lib.directory? || f.include.directory?
      s << "\nFor compilers to find this software you may need to set:\n"
      s << "    LDFLAGS:  -L#{f.opt_lib}\n" if f.lib.directory?
      s << "    CPPFLAGS: -I#{f.opt_include}\n" if f.include.directory?
      if which("pkg-config", ENV["HOMEBREW_PATH"]) &&
         ((f.lib/"pkgconfig").directory? || (f.share/"pkgconfig").directory?)
        s << "For pkg-config to find this software you may need to set:\n"
        s << "    PKG_CONFIG_PATH: #{f.opt_lib}/pkgconfig\n" if (f.lib/"pkgconfig").directory?
        s << "    PKG_CONFIG_PATH: #{f.opt_share}/pkgconfig\n" if (f.share/"pkgconfig").directory?
      end
    end
    s << "\n"
  end

  def function_completion_caveats(shell)
    return unless keg
    return unless which(shell.to_s, ENV["HOMEBREW_PATH"])

    completion_installed = keg.completion_installed?(shell)
    functions_installed = keg.functions_installed?(shell)
    return unless completion_installed || functions_installed

    installed = []
    installed << "completions" if completion_installed
    installed << "functions" if functions_installed

    root_dir = f.keg_only? ? f.opt_prefix : HOMEBREW_PREFIX

    case shell
    when :bash
      <<~EOS
        Bash completion has been installed to:
          #{root_dir}/etc/bash_completion.d
      EOS
    when :zsh
      <<~EOS
        zsh #{installed.join(" and ")} have been installed to:
          #{root_dir}/share/zsh/site-functions
      EOS
    when :fish
      fish_caveats = "fish #{installed.join(" and ")} have been installed to:"
      fish_caveats << "\n  #{root_dir}/share/fish/vendor_completions.d" if completion_installed
      fish_caveats << "\n  #{root_dir}/share/fish/vendor_functions.d" if functions_installed
      fish_caveats
    end
  end

  def python_caveats
    return unless keg
    return unless keg.python_site_packages_installed?

    s = nil
    homebrew_site_packages = Language::Python.homebrew_site_packages
    user_site_packages = Language::Python.user_site_packages "python"
    pth_file = user_site_packages/"homebrew.pth"
    instructions = <<~EOS.gsub(/^/, "  ")
      mkdir -p #{user_site_packages}
      echo 'import site; site.addsitedir("#{homebrew_site_packages}")' >> #{pth_file}
    EOS

    if f.keg_only?
      keg_site_packages = f.opt_prefix/"lib/python2.7/site-packages"
      unless Language::Python.in_sys_path?("python", keg_site_packages)
        s = <<~EOS
          If you need Python to find bindings for this keg-only formula, run:
            echo #{keg_site_packages} >> #{homebrew_site_packages/f.name}.pth
        EOS
        s += instructions unless Language::Python.reads_brewed_pth_files?("python")
      end
      return s
    end

    return if Language::Python.reads_brewed_pth_files?("python")

    if !Language::Python.in_sys_path?("python", homebrew_site_packages)
      s = <<~EOS
        Python modules have been installed and Homebrew's site-packages is not
        in your Python sys.path, so you will not be able to import the modules
        this formula installed. If you plan to develop with these modules,
        please run:
      EOS
      s += instructions
    elsif keg.python_pth_files_installed?
      s = <<~EOS
        This formula installed .pth files to Homebrew's site-packages and your
        Python isn't configured to process them, so you will not be able to
        import the modules this formula installed. If you plan to develop
        with these modules, please run:
      EOS
      s += instructions
    end
    s
  end

  def elisp_caveats
    return if f.keg_only?
    return unless keg
    return unless keg.elisp_installed?

    <<~EOS
      Emacs Lisp files have been installed to:
        #{HOMEBREW_PREFIX}/share/emacs/site-lisp/#{f.name}
    EOS
  end

  def plist_caveats; end

  def plist_path
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
    destination_path = Pathname.new(File.expand_path(destination))

    destination_path/plist_filename
  end
end

require "extend/os/caveats"
