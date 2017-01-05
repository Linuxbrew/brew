# Versions

Now that [Homebrew/versions](https://github.com/homebrew/homebrew-versions) has been deprecated [Homebrew/core](https://github.com/homebrew/homebrew-core) supports multiple versions of formulae with a new naming format.

In [Homebrew/versions](https://github.com/homebrew/homebrew-versions) the formula for GCC 6 was named `gcc6.rb` and began `class Gcc6 < Formula`. In [Homebrew/core](https://github.com/homebrew/homebrew-core) this same formula is named `gcc@6.rb` and begins `class GccAT6 < Formula`.

## Acceptable Versioned Formulae
Homebrew's versions are not intended to be used for any old versions you personally require for your project; formulae submitted should be expected to be used by a large number of people and still supported by their upstream projects.

Versioned formulae we include must meet the following standards:

* Versioned formulae should differ in major/minor (not patch) versions from the current stable release. This is because patch versions indicate bug or security updates and we want to ensure you apply security updates.
* Formulae that depend on versioned formulae must not depend on the same formulae at two different versions twice in their recursive dependencies. For example, if you depend on `openssl@1.0` and `foo`, and `foo` depends on `openssl` then you must instead use `openssl`.
* Versioned formulae should strive to be linked at the same time as their non-versioned counterpart (without patching). If this is not possible, favour either `conflicts_with` or `keg_only` depending on whether users expect to have multiple versions installed at once or not.

You should create your own [tap](https://github.com/Homebrew/brew/blob/master/docs/How-to-Create-and-Maintain-a-Tap.md) for formulae you or your organisation wishes to control the versioning of or those that do not meet the above standards.
