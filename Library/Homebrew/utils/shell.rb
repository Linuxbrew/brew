module Utils
  SHELL_PROFILE_MAP = {
    bash: "~/.bash_profile",
    csh: "~/.cshrc",
    fish: "~/.config/fish/config.fish",
    ksh: "~/.kshrc",
    sh: "~/.bash_profile",
    tcsh: "~/.tcshrc",
    zsh: "~/.zshrc",
  }.freeze

  module Shell
    UNSAFE_SHELL_CHAR = %r{([^A-Za-z0-9_\-.,:/@\n])}

    # take a path and heuristically convert it
    # to a shell name, return nil if there's no match
    def path_to_shell(path)
      # we only care about the basename
      shell_name = File.basename(path)
      # handle possible version suffix like `zsh-5.2`
      shell_name.sub!(/-.*\z/m, "")
      shell_name.to_sym if %w[bash csh fish ksh sh tcsh zsh].include?(shell_name)
    end
    module_function :path_to_shell

    def preferred_shell
      path_to_shell(ENV.fetch("SHELL", ""))
    end
    module_function :preferred_shell

    def parent_shell
      path_to_shell(`ps -p #{Process.ppid} -o ucomm=`.strip)
    end
    module_function :parent_shell

    def csh_quote(str)
      # ruby's implementation of shell_escape
      str = str.to_s
      return "''" if str.empty?
      str = str.dup
      # anything that isn't a known safe character is padded
      str.gsub!(UNSAFE_SHELL_CHAR, "\\\\" + "\\1")
      # newlines have to be specially quoted in csh
      str.gsub!(/\n/, "'\\\n'")
      str
    end
    module_function :csh_quote

    def sh_quote(str)
      # ruby's implementation of shell_escape
      str = str.to_s
      return "''" if str.empty?
      str = str.dup
      # anything that isn't a known safe character is padded
      str.gsub!(UNSAFE_SHELL_CHAR, "\\\\" + "\\1")
      str.gsub!(/\n/, "'\n'")
      str
    end
    module_function :sh_quote

    # quote values. quoting keys is overkill
    def export_value(shell, key, value)
      case shell
      when :bash, :ksh, :sh, :zsh
        "export #{key}=\"#{sh_quote(value)}\""
      when :fish
        # fish quoting is mostly Bourne compatible except that
        # a single quote can be included in a single-quoted string via \'
        # and a literal \ can be included via \\
        "set -gx #{key} \"#{sh_quote(value)}\""
      when :csh, :tcsh
        "setenv #{key} #{csh_quote(value)};"
      end
    end
    module_function :export_value

    # return the shell profile file based on users' preferred shell
    def shell_profile
      SHELL_PROFILE_MAP.fetch(preferred_shell, "~/.bash_profile")
    end
    module_function :shell_profile

    def prepend_path_in_shell_profile(path)
      case preferred_shell
      when :bash, :ksh, :sh, :zsh, nil
        "echo 'export PATH=\"#{sh_quote(path)}:$PATH\"' >> #{shell_profile}"
      when :csh, :tcsh
        "echo 'setenv PATH #{csh_quote(path)}:$PATH' >> #{shell_profile}"
      when :fish
        "echo 'set -g fish_user_paths \"#{sh_quote(path)}\" $fish_user_paths' >> #{shell_profile}"
      end
    end
    module_function :prepend_path_in_shell_profile
  end
end
