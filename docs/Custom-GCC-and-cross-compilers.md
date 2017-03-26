# Custom GCC and Cross Compilers

Homebrew depends on having an up-to-date version of Xcode because it comes with
specific versions of build tools, e.g. `clang`.

Installing a custom version of GCC or `autotools` into the `PATH` has the
potential to break lots of compiles so we prefer the Apple- or Homebrew-provided
compilers.

Cross-compilers based on GCC will typically be "keg-only" and therefore not
linked into the path by default.

Rather than merging in brews for either of these cases at this time, we're
listing them on this page. If you come up with a formula for a new version of
GCC or cross-compiler suite, please link it in here.

* Homebrew provides a `gcc` formula for use with Xcode 4.2+ or when needing
C++11 support on earlier versions.
* Homebrew provides older GCC formulae, e.g. `gcc@4.8` and `gcc@6`.
* [RISC-V](https://github.com/riscv/homebrew-riscv) provides the RISC-V
toolchain including binutils and GCC.
