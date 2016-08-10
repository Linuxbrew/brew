require "requirement"

class GPGRequirement < Requirement
  fatal true
  default_formula "gnupg2"

  satisfy(:build_env => false) { gpg2 || gpg }

  # MacGPG2/GPGTools installs GnuPG 2.0.x as a vanilla `gpg` symlink
  # pointing to `gpg2`, as do we. Ensure we're actually using a 2.0 `gpg`.
  # Temporarily, only support 2.0.x rather than the 2.1.x "modern" series.
  def gpg
    which_all("gpg").detect do |gpg|
      gpg_short_version = Utils.popen_read(gpg, "--version")[/\d\.\d/, 0]
      next unless gpg_short_version
      Version.create(gpg_short_version.to_s) == Version.create("2.0")
    end
  end

  def gpg2
    which_all("gpg2").detect do |gpg2|
      gpg2_short_version = Utils.popen_read(gpg2, "--version")[/\d\.\d/, 0]
      next unless gpg2_short_version
      Version.create(gpg2_short_version.to_s) == Version.create("2.0")
    end
  end
end
