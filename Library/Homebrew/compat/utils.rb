# return the shell profile file based on users' preference shell
def shell_profile
  opoo "shell_profile has been deprecated in favor of Utils::Shell.profile"
  case ENV["SHELL"]
  when %r{/(ba)?sh} then "~/.bash_profile"
  when %r{/zsh} then "~/.zshrc"
  when %r{/ksh} then "~/.kshrc"
  else "~/.bash_profile"
  end
end
