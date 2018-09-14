class SkipLinuxRequirement < Requirement
  fatal true

  satisfy build_env: false do
    next true if ENV["HOMEBREW_FORCE_LINUX"]
    next true unless OS.linux?
    false
  end

  def message
    <<~EOS
      This formula does not currently work on Linux. A pull request
      to fix it is most welcome! Run `brew edit FORMULA` and remove the
      line `depends_on :skip_linux`. Run `brew install FORMULA`. Edit the
      formula to fix any errors, and try installing again. When you're
      successful, please open a pull request! See here for details:
      https://github.com/Linuxbrew/homebrew-core/blob/master/CONTRIBUTING.md
    EOS
  end

  def display_s
    "works on Linux"
  end
end
