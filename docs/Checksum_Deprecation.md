# MD5 and SHA-1 Deprecation

During early 2015 Homebrew started the process of deprecating _SHA1_ for package
integrity verification. Since then every formulae under the Homebrew organisation
has been moved onto _SHA256_ verification; this includes both source packages
and our precompiled packages (bottles).

We have stopped supporting _SHA1_ and _MD5_ entirely.
_MD5_ checksums were removed from core formulae in 2012 but until April 2015
if you tried to install a formula still using one Homebrew wouldn't actively stop you.

We removed _SHA1_ support in **November 2016**,
21 months after we started warning people to move away from it for verification.
This is enforced in the same way _MD5_ is, by blocking the installation of that
individual formula until the checksum is migrated.

From March 20th 2016 we've stepped up the visibility of that notification & you'll start
seeing deprecation warnings when installing _SHA1_-validated formula.
If you see these please consider reporting it to where the formula originated.

This means custom taps, local custom formulae, etc need to be migrated to use
_SHA256_ before you can install them.
