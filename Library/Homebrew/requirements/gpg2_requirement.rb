require "requirement"
require "gpg"

class GPG2Requirement < Requirement
  fatal true
  default_formula "gnupg"

  # GPGTools installs GnuPG 2.0.x as a `gpg` symlink pointing
  # to `gpg2`. Our `gnupg` installs only a non-symlink `gpg`.
  # The aim is to retain support for any version above 2.0.
  satisfy(build_env: false) { Gpg.gpg || Gpg.gpg2 }
end
