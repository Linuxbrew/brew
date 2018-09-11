# Versions

Now that [homebrew/versions](https://github.com/homebrew/homebrew-versions) has been deprecated, [homebrew/core](https://github.com/homebrew/homebrew-core) supports multiple versions of formulae with a new naming format.

In [homebrew/versions](https://github.com/homebrew/homebrew-versions) the formula for GCC 6 was named `gcc6.rb` and began with `class Gcc6 < Formula`. In [homebrew/core](https://github.com/homebrew/homebrew-core) this same formula is named `gcc@6.rb` and begins with `class GccAT6 < Formula`.

## Acceptable versioned formulae
Versioned formulae we include in [homebrew/core](https://github.com/homebrew/homebrew-core) must meet the following standards:

* Versioned software should build on all Homebrew's supported versions of macOS.
* Versioned formulae should differ in major/minor (not patch) versions from the current stable release. This is because patch versions indicate bug or security updates and we want to ensure you apply security updates.
* Upstream should have a release branch for the versioned formulae version and still make security updates for that version, when necessary. For example, [PHP 5.5 was not a supported version but PHP 7.2 was](http://php.net/supported-versions.php) in January 2018
* Formulae that depend on versioned formulae must not depend on the same formulae at two different versions twice in their recursive dependencies. For example, if you depend on `openssl@1.0` and `foo`, and `foo` depends on `openssl` then you must instead use `openssl`.
* Versioned formulae should only be linkable at the same time as their non-versioned counterpart if the upstream project provides support for it, e.g. using suffixed binaries. If this is not possible, use `keg_only :versioned_formula` to allow users to have multiple versions installed at once.
* A `keg_only :versioned_formula` should not `post_install` anything in the `HOMEBREW_PREFIX` that conflicts with or duplicates the non-versioned counterpart (or other versioned formulae). For example, a `node@6` formula should not install its `npm` into `HOMEBREW_PREFIX` like the `node` formula does.
* Versioned formulae submitted should be expected to be used by a large number of people. If this ceases to be the case: they will be removed. We will aim not to remove those in the [top 3,000 `install_on_request` formulae](https://brew.sh/analytics/install-on-request/).
* Versioned formulae should not have `resource`s that require security updates. For example, a `node@6` formula should not have an `npm` resource but instead rely on the `npm` provided by the upstream tarball.
* Versioned formulae should be as similar as possible and sensible to the unversioned formulae. Creating or updating a versioned formula should be a chance to ask questions of the unversioned formula e.g. can some unused or useless options be removed or made default?
* No more than five versions of a formula (including the non-versioned one) will be supported at any given time, regardless of usage. When removing formulae that violate this we will aim to do so based on usage and support status rather than age.

Homebrew's versions are not intended to be used for any old versions you personally require for your project. You should create your own [tap](How-to-Create-and-Maintain-a-Tap.md) for formulae you or your organisation wish to control the versioning of or those that do not meet the above standards. Software that has regular API or ABI breaking releases still needs to meet all the above requirements; that a `brew upgrade` has broken something for you is not an argument for us to add and maintain a formula for you.

If there is a formula that currently exists in the Homebrew/homebrew-core repository or has existed in the past (i.e. was migrated or deleted), you can recover it for your own use with the `brew extract` command. This will copy the desired version of the formula into a custom tap. For example, if your project depends on `automake` 1.12 instead of the most recent version, you can obtain the `automake` formula at version 1.12 by running `brew extract automake $YOUR_GITHUB_USER/$YOUR_TAP_REPOSITORY_NAME --version=1.12`. Formulae obtained this way may have use deprecated, disabled or removed Homebrew syntax (e.g. checksums may have `sha1` checksums instead of `sha256`); the `brew extract` command does not edit or update formulae to meet current standards and style requirements.

We may temporarily add versioned formulae for our own needs that do not meet these standards in [homebrew/core](https://github.com/homebrew/homebrew-core). The presence of a versioned formula there does not imply it will be maintained indefinitely or that we are willing to accept any more versions that do not meet the requirements above.
