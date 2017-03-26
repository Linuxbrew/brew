# Versions

Now that [homebrew/versions](https://github.com/homebrew/homebrew-versions) has been deprecated, [homebrew/core](https://github.com/homebrew/homebrew-core) supports multiple versions of formulae with a new naming format.

In [homebrew/versions](https://github.com/homebrew/homebrew-versions) the formula for GCC 6 was named `gcc6.rb` and began with `class Gcc6 < Formula`. In [homebrew/core](https://github.com/homebrew/homebrew-core) this same formula is named `gcc@6.rb` and begins with `class GccAT6 < Formula`.

## Acceptable versioned formulae
Homebrew's versions are not intended to be used for any old versions you personally require for your project; formulae submitted should be expected to be used by a large number of people and still supported by their upstream projects.

Versioned formulae we include must meet the following standards:

* Versioned formulae should differ in major/minor (not patch) versions from the current stable release. This is because patch versions indicate bug or security updates and we want to ensure you apply security updates.
* Formulae that depend on versioned formulae must not depend on the same formulae at two different versions twice in their recursive dependencies. For example, if you depend on `openssl@1.0` and `foo`, and `foo` depends on `openssl` then you must instead use `openssl`.
* Versioned formulae should only be linkable at the same time as their non-versioned counterpart if the upstream project provides support for it, e.g. using suffixed binaries. If this is not possible, use `keg_only :versioned_formula` to allow users to have multiple versions installed at once.

You should create your own [tap](How-to-Create-and-Maintain-a-Tap.md) for formulae you or your organisation wishes to control the versioning of or those that do not meet the above standards.
