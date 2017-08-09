require "requirement"
require "gpg"

class GPG2Requirement < Requirement
  fatal true
  default_formula "gnupg"

  # GPGTools installs GnuPG 2.0.x as a vanilla `gpg` symlink
  # pointing to `gpg2`. Homebrew install 2.1.x as a non-symlink `gpg`.
  # We support both the 2.0.x "stable" and 2.1.x "modern" series here.
  satisfy(build_env: false) { Gpg.gpg || Gpg.gpg2 }
end
