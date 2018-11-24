module Utils
  module Shell
    module_function

    # take a path and heuristically convert it
    # to a shell name, return nil if there's no match
    def from_path(path)
      # we only care about the basename
      shell_name = File.basename(path)
      # handle possible version suffix like `zsh-5.2`
      shell_name.sub!(/-.*\z/m, "")
      shell_name.to_sym if %w[bash csh fish ksh sh tcsh zsh].include?(shell_name)
    end

    def preferred
      from_path(ENV.fetch("SHELL", ""))
    end

    def parent
      from_path(`ps -p #{Process.ppid} -o ucomm=`.strip)
    end

    # quote values. quoting keys is overkill
    def export_value(key, value, shell = preferred)
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

    # return the shell profile file based on user's preferred shell
    def profile
      SHELL_PROFILE_MAP.fetch(preferred, "~/.bash_profile")
    end

    def set_variable_in_profile(variable, value)
      case preferred
      when :bash, :ksh, :sh, :zsh, nil
        "echo 'export #{variable}=#{sh_quote(value)}' >> #{profile}"
      when :csh, :tcsh
        "echo 'setenv #{variable} #{csh_quote(value)}' >> #{profile}"
      when :fish
        "echo 'set -gx #{variable} #{sh_quote(value)}' >> #{profile}"
      end
    end

    def prepend_path_in_profile(path)
      case preferred
      when :bash, :ksh, :sh, :zsh, nil
        "echo 'export PATH=\"#{sh_quote(path)}:$PATH\"' >> #{profile}"
      when :csh, :tcsh
        "echo 'setenv PATH #{csh_quote(path)}:$PATH' >> #{profile}"
      when :fish
        "echo 'set -g fish_user_paths \"#{sh_quote(path)}\" $fish_user_paths' >> #{profile}"
      end
    end

    SHELL_PROFILE_MAP = {
      bash: "~/.bash_profile",
      csh:  "~/.cshrc",
      fish: "~/.config/fish/config.fish",
      ksh:  "~/.kshrc",
      sh:   "~/.bash_profile",
      tcsh: "~/.tcshrc",
      zsh:  "~/.zshrc",
    }.freeze

    UNSAFE_SHELL_CHAR = %r{([^A-Za-z0-9_\-.,:/@~\n])}.freeze

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
  end
end
