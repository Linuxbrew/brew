require "requirement"
require "gpg"

class GPG2Requirement < Requirement
  fatal true
  default_formula "gnupg2"

  # MacGPG2/GPGTools installs GnuPG 2.0.x as a vanilla `gpg` symlink
  # pointing to `gpg2`, as do we. Ensure we're actually using a 2.0 `gpg`.
  # Temporarily, only support 2.0.x rather than the 2.1.x "modern" series.
  satisfy(build_env: false) { Gpg.gpg2 || Gpg.gpg }
end
