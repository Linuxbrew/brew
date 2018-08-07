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
    caveats << elisp_caveats
    caveats.compact.join("\n")
  end

  delegate [:empty?, :to_s] => :caveats

  def keg_only_text(skip_reason: false)
    return unless f.keg_only?

    s = if skip_reason
      ""
    else
      <<~EOS
        #{f.name} is keg-only, which means it was not symlinked into #{HOMEBREW_PREFIX},
        because #{f.keg_only_reason.to_s.chomp}.
      EOS
    end

    if f.bin.directory? || f.sbin.directory?
      s << <<~EOS

        If you need to have #{f.name} first in your PATH run:
      EOS
      if f.bin.directory?
        s << "  #{Utils::Shell.prepend_path_in_profile(f.opt_bin.to_s)}\n"
      end
      if f.sbin.directory?
        s << "  #{Utils::Shell.prepend_path_in_profile(f.opt_sbin.to_s)}\n"
      end
    end

    if f.lib.directory? || f.include.directory?
      s << <<~EOS

        For compilers to find #{f.name} you may need to set:
      EOS

      if f.lib.directory?
        s << "  #{Utils::Shell.export_value("LDFLAGS", "-L#{f.opt_lib}")}\n"
      end

      if f.include.directory?
        s << "  #{Utils::Shell.export_value("CPPFLAGS", "-I#{f.opt_include}")}\n"
      end

      if which("pkg-config", ENV["HOMEBREW_PATH"]) &&
         ((f.lib/"pkgconfig").directory? || (f.share/"pkgconfig").directory?)
        s << <<~EOS

          For pkg-config to find #{f.name} you may need to set:
        EOS

        if (f.lib/"pkgconfig").directory?
          s << "  #{Utils::Shell.export_value("PKG_CONFIG_PATH", "#{f.opt_lib}/pkgconfig")}\n"
        end

        if (f.share/"pkgconfig").directory?
          s << "  #{Utils::Shell.export_value("PKG_CONFIG_PATH", "#{f.opt_share}/pkgconfig")}\n"
        end
      end
    end
    s << "\n"
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
