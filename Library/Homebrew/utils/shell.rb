module Utils
  SHELL_PROFILE_MAP = {
    :bash => "~/.bash_profile",
    :csh => "~/.cshrc",
    :fish => "~/.config/fish/config.fish",
    :ksh => "~/.kshrc",
    :sh => "~/.bash_profile",
    :tcsh => "~/.tcshrc",
    :zsh => "~/.zshrc",
  }.freeze

  module Shell
    UNSAFE_SHELL_CHAR = /([^A-Za-z0-9_\-.,:\/@\n])/

    # take a path and heuristically convert it
    # to a shell name, return nil if there's no match
    def self.path_to_shell(path)
      # we only care about the basename
      shell_name = File.basename(path)
      # handle possible version suffix like `zsh-5.2`
      shell_name.sub!(/-.*\z/m, "")
      shell_name.to_sym if %w[bash csh fish ksh sh tcsh zsh].include?(shell_name)
    end

    def self.preferred_shell
      path_to_shell(ENV.fetch("SHELL", ""))
    end

    def self.parent_shell
      path_to_shell(`ps -p #{Process.ppid} -o ucomm=`.strip)
    end

    def self.csh_quote(str)
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
    
    def self.sh_quote(str)
      # ruby's implementation of shell_escape
      str = str.to_s
      return "''" if str.empty?
      str = str.dup
      # anything that isn't a known safe character is padded
      str.gsub!(UNSAFE_SHELL_CHAR, "\\\\" + "\\1")
      str.gsub!(/\n/, "'\n'")
      str
    end

    # quote values. quoting keys is overkill
    def self.export_value(shell, key, value)
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

    # return the shell profile file based on users' preferred shell
    def self.shell_profile
      SHELL_PROFILE_MAP.fetch(preferred_shell, "~/.bash_profile")
    end

    def self.prepend_path_in_shell_profile(path)
      case preferred_shell 
      when :bash, :ksh, :sh, :zsh, nil
        "echo 'export PATH=\"#{sh_quote(path)}:$PATH\"' >> #{shell_profile}"
      when :csh, :tcsh
        "echo 'setenv PATH #{csh_quote(path)}:$PATH' >> #{shell_profile}"
      when :fish
        "echo 'set -g fish_user_paths \"#{sh_quote(path)}\" $fish_user_paths' >> #{shell_profile}"
      end
    end
  end
end
