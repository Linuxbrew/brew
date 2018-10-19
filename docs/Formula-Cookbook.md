# Formula Cookbook

A *formula* is a package definition written in Ruby. It can be created with `brew create <URL>` where `<URL>` is a zip or tarball, installed with `brew install <formula>`, and debugged with `brew install --debug --verbose <formula>`. Formulae use the [Formula API](https://www.rubydoc.info/github/Homebrew/brew/master/Formula) which provides various Homebrew-specific helpers.

## Homebrew terminology

| Term           | Description                                                | Example                                                         |
|----------------|------------------------------------------------------------|-----------------------------------------------------------------|
| **Formula**    | The package definition                                     | `/usr/local/Homebrew/Library/Taps/homebrew/homebrew-core/Formula/foo.rb` |
| **Keg**        | The installation prefix of a **Formula**                   | `/usr/local/Cellar/foo/0.1`                                     |
| **opt prefix** | A symlink to the active version of a **Keg**               | `/usr/local/opt/foo `                                           |
| **Cellar**     | All **Kegs** are installed here                            | `/usr/local/Cellar`                                             |
| **Tap**        | A Git repository of **Formulae** and/or commands | `/usr/local/Homebrew/Library/Taps/homebrew/homebrew-core`   |
| **Bottle**     | Pre-built **Keg** used instead of building from source     | `qt-4.8.4.mavericks.bottle.tar.gz`                              |
| **Cask**       | An [extension of Homebrew](https://github.com/Homebrew/homebrew-cask) to install macOS native apps  | `/Applications/MacDown.app/Contents/SharedSupport/bin/macdown` |
| **Brew Bundle**| An [extension of Homebrew](https://github.com/Homebrew/homebrew-bundle) to describe dependencies    | `brew 'myservice', restart_service: true` |

## An introduction

Homebrew uses Git for downloading updates and contributing to the project.

Homebrew installs to the `Cellar` and then symlinks some of the installation into `/usr/local` so that other programs can see what's going on. We suggest you `brew ls` a few of the kegs in your Cellar to see how it is all arranged.

Packages are installed according to their formulae, which live in `/usr/local/Homebrew/Library/Taps/homebrew/homebrew-core/Formula`. Check one out a simple one, e.g. `brew edit etl` (or [`etl`](https://github.com/Homebrew/homebrew-core/blob/master/Formula/etl.rb)) or a more advanced one, e.g. `brew edit git` (or [`git`](https://github.com/Homebrew/homebrew-core/blob/master/Formula/git.rb)).

## Basic instructions

Make sure you run `brew update` before you start. This turns your Homebrew installation into a Git repository.

Before submitting a new formula make sure your package:

* meets all our [Acceptable Formulae](Acceptable-Formulae.md) requirements
* isn't already in Homebrew (check `brew search <formula>`)
* isn't already waiting to be merged (check the [issue tracker](https://github.com/Homebrew/homebrew-core/pulls))
* is still supported by upstream (i.e. doesn't require extensive patching)
* has a stable, tagged version (i.e. not just a GitHub repository with no versions)
* passes all `brew audit --new-formula <formula>` tests

Before submitting a new formula make sure you read over our [contribution guidelines](https://github.com/Homebrew/brew/blob/master/CONTRIBUTING.md#contributing-to-homebrew).

### Grab the URL

Run `brew create` with a URL to the source tarball:

```sh
brew create https://example.com/foo-0.1.tar.gz
```

This creates `/usr/local/Homebrew/Library/Taps/homebrew/homebrew-core/Formula/foo.rb` and opens it in your `EDITOR`. It'll look something like:

```ruby
class Foo < Formula
  desc ""
  homepage ""
  url "https://example.com/foo-0.1.tar.gz"
  sha256 "85cc828a96735bdafcf29eb6291ca91bac846579bcef7308536e0c875d6c81d7"

  # depends_on "cmake" => :build

  def install
    # ENV.deparallelize
    system "./configure", "--disable-debug",
                          "--disable-dependency-tracking",
                          "--disable-silent-rules",
                          "--prefix=#{prefix}"
    # system "cmake", ".", *std_cmake_args
    system "make", "install"
  end

  test do
    system "false"
  end
end
```

If `brew` said `Warning: Version cannot be determined from URL` when doing the `create` step, you’ll need to explicitly add the correct [`version`](https://www.rubydoc.info/github/Homebrew/brew/master/Formula#version-class_method) to the formula and then save the formula.

Homebrew will try to guess the formula’s name from its URL. If it fails to do
so you can override this with `brew create <URL> --set-name <name>`.

### Fill in the `homepage`

**We don’t accept formulae without a [`homepage`](https://www.rubydoc.info/github/Homebrew/brew/master/Formula#homepage%3D-class_method)!**

An SSL/TLS (https) [`homepage`](https://www.rubydoc.info/github/Homebrew/brew/master/Formula#homepage%3D-class_method) is preferred, if one is available.

Try to summarize from the [`homepage`](https://www.rubydoc.info/github/Homebrew/brew/master/Formula#homepage%3D-class_method) what the formula does in the [`desc`](https://www.rubydoc.info/github/Homebrew/brew/master/Formula#desc%3D-class_method)ription. Note that the [`desc`](https://www.rubydoc.info/github/Homebrew/brew/master/Formula#desc%3D-class_method)ription is automatically prepended with the formula name.

### Check the build system

```sh
brew install --interactive foo
```

You’re now at a new prompt with the tarball extracted to a temporary sandbox.

Check the package’s `README`. Does the package install with `./configure`, `cmake`, or something else? Delete the commented out `cmake` lines if the package uses `./configure`.

### Check for dependencies

The `README` probably tells you about dependencies and Homebrew or macOS probably already has them. You can check for Homebrew dependencies with `brew search`. Some common dependencies that macOS comes with:

* `libexpat`
* `libGL`
* `libiconv`
* `libpcap`
* `libxml2`
* `python`
* `ruby`

There are plenty of others; check `/usr/lib` for them.

We generally try not to duplicate system libraries and complicated tools in core Homebrew but we do duplicate some commonly used tools.

Special exceptions are OpenSSL and LibreSSL. Things that use either *should* be built using Homebrew’s shipped equivalent and our Brew Test Bot's post-install `audit` will warn if it detects you haven't done this.

Homebrew’s OpenSSL is [`keg_only`](https://www.rubydoc.info/github/Homebrew/brew/master/Formula#keg_only-class_method)
to avoid conflicting with the system so sometimes formulae need to
have environment variables set or special configuration flags passed
to locate our OpenSSL. You can see this mechanism in the
[`clamav`](https://github.com/Homebrew/homebrew-core/blob/89c4574ef1a6d15e92196637ff315a0a4bb3e289/Formula/clamav.rb#L37)
formula. Usually this is unnecessary because Homebrew sets up our [build environment](https://github.com/Homebrew/brew/blob/master/Library/Homebrew/extend/ENV/super.rb)
to favour finding [`keg_only`](https://www.rubydoc.info/github/Homebrew/brew/master/Formula#keg_only-class_method) formulae first.

**Important:** `$(brew --prefix)/bin` is NOT on the `PATH` during formula installation. If you have dependencies at build time, you must specify them and `brew` will add them to the `PATH` or create a [`Requirement`](https://www.rubydoc.info/github/Homebrew/brew/master/Requirement).

### Specifying other formulae as dependencies

```ruby
class Foo < Formula
  depends_on "pkg-config"
  depends_on "jpeg"
  depends_on "readline" => :recommended
  depends_on "gtk+" => :optional
  depends_on "httpd" => [:build, :test]
  depends_on :x11 => :optional
  depends_on :xcode => "9.3"
end
```

A String (e.g. `"jpeg"`) specifies a formula dependency.

A Symbol (e.g. `:x11`) specifies a [`Requirement`](https://www.rubydoc.info/github/Homebrew/brew/master/Requirement) which can be fulfilled by one or more formulae, casks or other system-wide installed software (e.g. X11).

A Hash (e.g. `=>`) adds information to a dependency. Given a String or Symbol, the value can be one or more of the following values:

* `:build` means that dependency is a build-time only dependency so it can
be skipped when installing from a bottle or when listing missing
dependencies using `brew missing`.
* `:test` means that dependency is only required when running `brew test`.
* `:optional` generates an implicit `with-foo` option for the formula.
This means that, given `depends_on "foo" => :optional`, the user must pass `--with-foo` in order to use the dependency.
* `:recommended` generates an implicit `without-foo` option, meaning that
the dependency is enabled by default and the user must pass
`--without-foo` to disable this dependency. The default
description can be overridden using the normal option syntax (in this case, the option declaration must precede the dependency):
    ```ruby
    option "with-foo", "Compile with foo bindings" # This overrides the generated description if you want to
    depends_on "foo" => :optional # Generated description would otherwise be "Build with foo support"
    ```
* Some [`Requirement`](https://www.rubydoc.info/github/Homebrew/brew/master/Requirement)s can also take a string specifying their minimum version that the formula depends on.

We frown on [`option`](https://www.rubydoc.info/github/Homebrew/brew/master/Formula#option-class_method)s in Homebrew/homebrew-core as they are not tested by CI.

### Specifying conflicts with other formulae

Sometimes there’s hard conflict between formulae, and it can’t be avoided or circumvented with [`keg_only`](https://www.rubydoc.info/github/Homebrew/brew/master/Formula#keg_only-class_method).

A good example formula for minor conflict is [`mbedtls`](https://github.com/Homebrew/homebrew-core/blob/master/Formula/mbedtls.rb), which ships and compiles a "Hello World" executable. This is obviously non-essential to `mbedtls`’s functionality, and conflict with the popular GNU [`hello`](https://github.com/Homebrew/homebrew-core/blob/master/Formula/hello.rb) formula would be overkill, so we just [remove it](https://github.com/Homebrew/homebrew-core/blob/966273060ad507fea490bd931971963de8b1a1dc/Formula/mbedtls.rb#L30-L31) during the installation process.

[`pdftohtml`](https://github.com/Homebrew/homebrew-core/blob/master/Formula/pdftohtml.rb) provides an example of a serious
conflict, where both formula ship an identically-named binary that is essential to functionality, so a [`conflicts_with`](https://www.rubydoc.info/github/Homebrew/brew/master/Formula#conflicts_with-class_method) is preferable.

As a general rule, [`conflicts_with`](https://www.rubydoc.info/github/Homebrew/brew/master/Formula#conflicts_with-class_method) should be a last-resort option. It’s a fairly blunt instrument.

The syntax for a conflict that can’t be worked around is:

```ruby
conflicts_with "blueduck", :because => "yellowduck also ships a duck binary"
```

### Formulae revisions

In Homebrew we sometimes accept formulae updates that don’t include a version bump. These include resource updates, new patches or fixing a security issue with a formula.

Occasionally, these updates require a forced-recompile of the formula itself or its dependents to either ensure formulae continue to function as expected or to close a security issue. This forced-recompile is known as a [`revision`](https://www.rubydoc.info/github/Homebrew/brew/master/Formula#revision%3D-class_method) and is inserted underneath the [`homepage`](https://www.rubydoc.info/github/Homebrew/brew/master/Formula#homepage%3D-class_method)/[`url`](https://www.rubydoc.info/github/Homebrew/brew/master/Formula#url-class_method)/[`sha256`](https://www.rubydoc.info/github/Homebrew/brew/master/Formula#sha256%3D-class_method) block.

When a dependent of a formula fails against a new version of that dependency it must receive a [`revision`](https://www.rubydoc.info/github/Homebrew/brew/master/Formula#revision%3D-class_method). An example of such failure can be seen [here](https://github.com/Homebrew/legacy-homebrew/issues/31195) and the fix [here](https://github.com/Homebrew/legacy-homebrew/pull/31207).

[`revision`](https://www.rubydoc.info/github/Homebrew/brew/master/Formula#revision%3D-class_method)s are also used for formulae that move from the system OpenSSL to the Homebrew-shipped OpenSSL without any other changes to that formula. This ensures users aren’t left exposed to the potential security issues of the outdated OpenSSL. An example of this can be seen in [this commit](https://github.com/Homebrew/legacy-homebrew/commit/6b9d60d474d72b1848304297d91adc6120ea6f96).

### Version scheme changes

Sometimes formulae have version schemes that change such that a direct comparison between two versions no longer produces the correct result. For example, a project might be version `13` and then decide to become `1.0.0`. As `13` is translated to `13.0.0` by our versioning system by default this requires intervention.

When a version scheme of a formula fails to recognise a new version as newer it must receive a [`version_scheme`](https://www.rubydoc.info/github/Homebrew/brew/master/Formula#version_scheme%3D-class_method). An example of this can be seen [here](https://github.com/Homebrew/homebrew-core/pull/4006).

### Double-check for dependencies

When you already have a lot of formulae installed, it's easy to miss a common dependency. You can double-check which libraries a binary links to with the `otool` command (perhaps you need to use `xcrun otool`):

```sh
$ otool -L /usr/local/bin/ldapvi
/usr/local/bin/ldapvi:
    /usr/local/opt/openssl/lib/libssl.1.0.0.dylib (compatibility version 1.0.0, current version 1.0.0)
    /usr/local/opt/openssl/lib/libcrypto.1.0.0.dylib (compatibility version 1.0.0, current version 1.0.0)
    /usr/local/lib/libglib-2.0.0.dylib (compatibility version 4201.0.0, current version 4201.0.0)
    /usr/local/opt/gettext/lib/libintl.8.dylib (compatibility version 10.0.0, current version 10.2.0)
    /usr/local/opt/readline/lib/libreadline.6.dylib (compatibility version 6.0.0, current version 6.3.0)
    /usr/local/lib/libpopt.0.dylib (compatibility version 1.0.0, current version 1.0.0)
    /usr/lib/libncurses.5.4.dylib (compatibility version 5.4.0, current version 5.4.0)
    /System/Library/Frameworks/LDAP.framework/Versions/A/LDAP (compatibility version 1.0.0, current version 2.4.0)
    /usr/lib/libresolv.9.dylib (compatibility version 1.0.0, current version 1.0.0)
    /usr/lib/libSystem.B.dylib (compatibility version 1.0.0, current version 1213.0.0)
```

### Specifying gems, Python modules, Go projects, etc. as dependencies

Homebrew doesn’t package already-packaged language-specific libraries. These should be installed directly from `gem`/`cpan`/`pip` etc.

If you're installing an application then use [`resource`](https://www.rubydoc.info/github/Homebrew/brew/master/Formula#resource-class_method)s for all language-specific dependencies:

```ruby
class Foo < Formula
  resource "pycrypto" do
    url "https://files.pythonhosted.org/packages/60/db/645aa9af249f059cc3a368b118de33889219e0362141e75d4eaf6f80f163/pycrypto-2.6.1.tar.gz"
    sha256 "f2ce1e989b272cfcb677616763e0a2e7ec659effa67a88aa92b3a65528f60a3c"
  end

  def install
    resource("pycrypto").stage { system "python", *Language::Python.setup_install_args(libexec/"vendor") }
  end
end
```

[`jrnl`](https://github.com/Homebrew/homebrew-core/blob/master/Formula/jrnl.rb) is an example of a formula that does this well. The end result means the user doesn't have to use `pip` or Python and can just run `jrnl`.

[homebrew-pypi-poet](https://github.com/tdsmith/homebrew-pypi-poet) can help you generate [`resource`](https://www.rubydoc.info/github/Homebrew/brew/master/Formula#resource-class_method) stanzas for the dependencies of your Python application.

### Install the formula

```sh
brew install --verbose --debug foo
```

`--debug` will ask you to open an interactive shell if the build fails so you can try to figure out what went wrong.

Check the top of the e.g. `./configure` output. Some configure scripts do not recognise e.g. `--disable-debug`. If you see a warning about it, remove the option from the formula.

### Add a test to the formula

Add a valid test to the [`test do`](https://www.rubydoc.info/github/Homebrew/brew/master/Formula#test-class_method) block of the formula. This will be run by `brew test foo` and the [Brew Test Bot](Brew-Test-Bot.md).

The [`test do`](https://www.rubydoc.info/github/Homebrew/brew/master/Formula#test-class_method) block automatically creates and changes to a temporary directory which
is deleted after run. You can access this [`Pathname`](https://www.rubydoc.info/github/Homebrew/brew/master/Pathname) with the [`testpath`](https://www.rubydoc.info/github/Homebrew/brew/master/Formula#testpath-instance_method)
function. The environment variable `HOME` is set to [`testpath`](https://www.rubydoc.info/github/Homebrew/brew/master/Formula#testpath-instance_method) within the [`test do`](https://www.rubydoc.info/github/Homebrew/brew/master/Formula#test-class_method) block.

We want tests that don't require any user input and test the basic functionality of the application. For example `foo build-foo input.foo` is a good test and (despite their widespread use) `foo --version` and `foo --help` are bad tests. However, a bad test is better than no test at all.

See [`cmake`](https://github.com/Homebrew/homebrew-core/blob/master/Formula/cmake.rb) for an example of a formula with a good test. The formula writes a basic `CMakeLists.txt` file into the test directory then calls CMake to generate Makefiles. This test checks that CMake doesn't e.g. segfault during basic operation. Another good example is [`tinyxml2`](https://github.com/Homebrew/homebrew-core/blob/master/Formula/tinyxml2.rb), which writes a small C++ source file into the test directory, compiles and links it against the tinyxml2 library and finally checks that the resulting program runs successfully.

### Manuals

Homebrew expects to find manual pages in `#{prefix}/share/man/...`, and not in `#{prefix}/man/...`.

Some software installs to `man` instead of `share/man`, so check the output and add a `"--mandir=#{man}"` to the `./configure` line if needed.

### A quick word on naming

Name the formula like the project markets the product. So it’s `pkg-config`, not `pkgconfig`; `sdl_mixer`, not `sdl-mixer` or `sdlmixer`.

The only exception is stuff like “Apache Ant”. Apache sticks “Apache” in front of everything, but we use the formula name `ant`. We only include the prefix in cases like `gnuplot` (because it’s part of the name) and `gnu-go` (because everyone calls it “GNU Go”—nobody just calls it “Go”). The word “Go” is too common and there are too many implementations of it.

If you’re not sure about the name, check its homepage, Wikipedia page and [what Debian calls it](https://www.debian.org/distrib/packages).

When Homebrew already has a formula called `foo` we typically do not accept requests to replace that formula with something else also named `foo`. This is to avoid both confusing and surprising users’ expectations.

When two formulae share an upstream name, e.g. [AESCrypt](https://github.com/Homebrew/homebrew-core/blob/master/Formula/aescrypt.rb) and [AES Crypt](https://github.com/Homebrew/homebrew-core/blob/master/Formula/aescrypt-packetizer.rb) the newer formula must typically adapt its name to avoid conflict with the current formula.

If you’re *still* not sure, just commit. We’ll apply some arbitrary rule and make a decision 😉.

When importing classes, Homebrew will require the formula and then create an instance of the class. It does this by assuming the formula name can be directly converted to the class name using a `regexp`. The rules are simple:

* `foo-bar.rb` => `FooBar`
* `foobar.rb` => `Foobar`

Thus, if you change the name of the class, you must also rename the file. Filenames should be all lowercase, and class names should be the strict CamelCase equivalent, e.g. formulae `gnu-go` and `sdl_mixer` become classes `GnuGo` and `SdlMixer`, even if part of their name is an acronym.

Add aliases by creating symlinks in an `Aliases` directory in the tap root.

### Audit the formula

You can run `brew audit --strict --online` to test formulae for adherence to Homebrew house style. The `audit` command includes warnings for trailing whitespace, preferred URLs for certain source hosts, and a lot of other style issues. Fixing these warnings before committing will make the process a lot quicker for everyone.

New formulae being submitted to Homebrew should run `brew audit --new-formula foo`. This command is performed by the Brew Test Bot on new submissions as part of the automated build and test process, and highlights more potential issues than the standard audit.

Use `brew info` and check if the version guessed by Homebrew from the URL is
correct. Add an explicit [`version`](https://www.rubydoc.info/github/Homebrew/brew/master/Formula#version-class_method) if not.

### Commit

Everything is built on Git, so contribution is easy:

```sh
brew update # required in more ways than you think (initializes the brew git repository if you don't already have it)
cd $(brew --repo homebrew/core)
# Create a new git branch for your formula so your pull request is easy to
# modify if any changes come up during review.
git checkout -b <some-descriptive-name> origin/master
git add Formula/foo.rb
git commit
```

The established standard for Git commit messages is:

* the first line is a commit summary of *50 characters or less*
* two (2) newlines, then
* explain the commit thoroughly.

At Homebrew, we like to put the name of the formula up front like so: `foobar 7.3 (new formula)`.
This may seem crazy short, but you’ll find that forcing yourself to summarise the commit encourages you to be atomic and concise. If you can’t summarise it in 50-80 characters, you’re probably trying to commit two commits as one. For a more thorough explanation, please read Tim Pope’s excellent blog post, [A Note About Git Commit Messages](https://tbaggery.com/2008/04/19/a-note-about-git-commit-messages.html).

The preferred commit message format for simple version updates is `foobar 7.3` and for fixes is `foobar: fix flibble matrix.`.

Ensure you reference any relevant GitHub issue, e.g. `Closes #12345` in the commit message. Homebrew’s history is the first thing future contributors will look to when trying to understand the current state of formulae they’re interested in.

### Push

Now you just need to push your commit to GitHub.

If you haven’t forked Homebrew yet, [go to the `homebrew-core` repository and hit the Fork button](https://github.com/Homebrew/homebrew-core).

If you have already forked Homebrew on GitHub, then you can manually push (just make sure you have been pulling from the `Homebrew/homebrew-core` master):

```sh
git push https://github.com/myname/homebrew-core/ <what-you-called-your-branch>
```

Now, [open a pull request](https://docs.brew.sh/How-To-Open-a-Homebrew-Pull-Request) for your changes.

* One formula per commit; one commit per formula.
* Keep merge commits out of the pull request.

## Convenience tools

### Messaging

Three commands are provided for displaying informational messages to the user:

* `ohai` for general info
* `opoo` for warning messages
* `odie` for error messages and immediately exiting

In particular, when a test needs to be performed before installation use `odie` to bail out gracefully. For example:

```ruby
if build.with?("qt") && build.with("qt5")
  odie "Options --with-qt and --with-qt5 are mutually exclusive."
end
system "make", "install"
```

### `bin.install "foo"`

You’ll see stuff like this in some formulae. This moves the file `foo` into the formula’s `bin` directory (`/usr/local/Cellar/pkg/0.1/bin`) and makes it executable (`chmod 0555 foo`).

### `inreplace`

[`inreplace`](https://www.rubydoc.info/github/Homebrew/brew/master/Utils/Inreplace) is a convenience function that can edit files in-place. For example:

```ruby
inreplace "path", before, after
```

`before` and `after` can be strings or regular expressions. You should use the block form if you need to make multiple replacements in a file:

```ruby
inreplace "path" do |s|
  s.gsub! /foo/, "bar"
  s.gsub! "123", "456"
end
```

Make sure you modify `s`! This block ignores the returned value.

[`inreplace`](https://www.rubydoc.info/github/Homebrew/brew/master/Utils/Inreplace) should be used instead of patches when patching something that will never be accepted upstream, e.g. making the software’s build system respect Homebrew’s installation hierarchy. If it's something that affects both Homebrew and MacPorts (i.e. macOS specific) it should be turned into an upstream submitted patch instead.

If you need modify variables in a `Makefile`, rather than using [`inreplace`](https://www.rubydoc.info/github/Homebrew/brew/master/Utils/Inreplace), pass them as arguments to `make`:

```ruby
system "make", "target", "VAR2=value1", "VAR2=value2", "VAR3=values can have spaces"
```

```ruby
system "make", "CC=#{ENV.cc}", "PREFIX=#{prefix}"
```

Note that values *can* contain unescaped spaces if you use the multiple-argument form of `system`.

## Patches

While [`patch`](https://www.rubydoc.info/github/Homebrew/brew/master/Formula#patch-class_method)es should generally be avoided, sometimes they are temporarily necessary.

When [`patch`](https://www.rubydoc.info/github/Homebrew/brew/master/Formula#patch-class_method)ing (i.e. fixing header file inclusion, fixing compiler warnings, etc.) the first thing to do is check whether or not the upstream project is aware of the issue. If not, file a bug report and/or submit your patch for inclusion. We may sometimes still accept your patch before it was submitted upstream but by getting the ball rolling on fixing the upstream issue you reduce the length of time we have to carry the patch around.

*Always justify a [`patch`](https://www.rubydoc.info/github/Homebrew/brew/master/Formula#patch-class_method) with a code comment!* Otherwise, nobody will know when it is safe to remove the patch, or safe to leave it in when updating the formula. The comment should include a link to the relevant upstream issue(s).

External [`patch`](https://www.rubydoc.info/github/Homebrew/brew/master/Formula#patch-class_method)es can be declared using resource-style blocks:

```ruby
patch do
  url "https://example.com/example_patch.diff"
  sha256 "85cc828a96735bdafcf29eb6291ca91bac846579bcef7308536e0c875d6c81d7"
end
```

A strip level of `-p1` is assumed. It can be overridden using a symbol argument:

```ruby
patch :p0 do
  url "https://example.com/example_patch.diff"
  sha256 "85cc828a96735bdafcf29eb6291ca91bac846579bcef7308536e0c875d6c81d7"
end
```

[`patch`](https://www.rubydoc.info/github/Homebrew/brew/master/Formula#patch-class_method)es can be declared in [`stable`](https://www.rubydoc.info/github/Homebrew/brew/master/Formula#stable-class_method), [`devel`](https://www.rubydoc.info/github/Homebrew/brew/master/Formula#devel-class_method), and [`head`](https://www.rubydoc.info/github/Homebrew/brew/master/Formula#head-class_method) blocks. Always use a block instead of a conditional, i.e. `stable do ... end` instead of `if build.stable? then ... end`.

```ruby
stable do
  # some other things...

  patch do
    url "https://example.com/example_patch.diff"
    sha256 "85cc828a96735bdafcf29eb6291ca91bac846579bcef7308536e0c875d6c81d7"
  end
end
```

Embedded (__END__) patches can be declared like so:

```ruby
patch :DATA
patch :p0, :DATA
```

with the patch data included at the end of the file:

```
__END__
diff --git a/foo/showfigfonts b/foo/showfigfonts
index 643c60b..543379c 100644
--- a/foo/showfigfonts
+++ b/foo/showfigfonts
@@ -14,6 +14,7 @@
…
```

Patches can also be embedded by passing a string. This makes it possible to provide multiple embedded patches while making only some of them conditional.

```ruby
patch :p0, "..."
```

In embedded patches, the string "HOMEBREW\_PREFIX" is replaced with the value of the constant `HOMEBREW_PREFIX` before the patch is applied.

### Creating the diff

```sh
brew install --interactive --git foo
# (make some edits)
git diff | pbcopy
brew edit foo
```

Now just paste into the formula after `__END__`.
Instead of `git diff | pbcopy`, for some editors `git diff >> path/to/your/formula/foo.rb` might help you ensure that the patch is not touched, e.g. white space removal, indentation changes, etc.

## Advanced formula tricks

If anything isn’t clear, you can usually figure it out by `grep`ping the `$(brew --repo homebrew/core)` directory. Please submit a pull request to amend this document if you think it will help!

### Unstable versions (`devel`, `head`)

Formulae can specify alternate downloads for the upstream project’s [`devel`](https://www.rubydoc.info/github/Homebrew/brew/master/Formula#devel-class_method) release (unstable but not `master`/`trunk`) or [`head`](https://www.rubydoc.info/github/Homebrew/brew/master/Formula#head-class_method) (`master`/`trunk`).

#### `devel`

The [`devel`](https://www.rubydoc.info/github/Homebrew/brew/master/Formula#devel-class_method) spec (activated by passing `--devel`) is used for a project’s unstable releases. It is specified in a block:

```ruby
devel do
  url "https://foo.com/foo-0.1.tar.gz"
  sha256 "85cc828a96735bdafcf29eb6291ca91bac846579bcef7308536e0c875d6c81d7"
end
```

You can test if the [`devel`](https://www.rubydoc.info/github/Homebrew/brew/master/Formula#devel-class_method) spec is in use with `build.devel?`.

#### `head`

[`head`](https://www.rubydoc.info/github/Homebrew/brew/master/Formula#head-class_method) URLs (activated by passing `--HEAD`) build the development cutting edge. Specifying it is easy:

```ruby
class Foo < Formula
  head "https://github.com/mxcl/lastfm-cocoa.git"
end
```

Homebrew understands `git`, `svn`, and `hg` URLs, and has a way to specify `cvs` repositories as a URL as well. You can test whether the [`head`](https://www.rubydoc.info/github/Homebrew/brew/master/Formula#head-class_method) is being built with `build.head?`.

To use a specific commit, tag, or branch from a repository, specify [`head`](https://www.rubydoc.info/github/Homebrew/brew/master/Formula#head-class_method) with the `:tag` and `:revision`, `:revision`, or `:branch` option, like so:

```ruby
class Foo < Formula
  head "https://github.com/some/package.git", :revision => "090930930295adslfknsdfsdaffnasd13"
                                         # or :branch => "develop" (the default is "master")
                                         # or :tag => "1_0_release",
                                         #    :revision => "090930930295adslfknsdfsdaffnasd13"
end
```

### Compiler selection

Sometimes a package fails to build when using a certain compiler. Since recent [Xcode versions](Xcode.md) no longer include a GCC compiler we cannot simply force the use of GCC. Instead, the correct way to declare this is the [`fails_with`](https://www.rubydoc.info/github/Homebrew/brew/master/Formula#fails_with-class_method) DSL method. A properly constructed [`fails_with`](https://www.rubydoc.info/github/Homebrew/brew/master/Formula#fails_with-class_method) block documents the latest compiler build version known to cause compilation to fail, and the cause of the failure. For example:

```ruby
fails_with :clang do
  build 211
  cause "Miscompilation resulting in segfault on queries"
end
```

`build` takes a Fixnum (an integer; you can find this number in your `brew --config` output). `cause` takes a String, and the use of heredocs is encouraged to improve readability and allow for more comprehensive documentation.

[`fails_with`](https://www.rubydoc.info/github/Homebrew/brew/master/Formula#fails_with-class_method) declarations can be used with any of `:gcc`, `:llvm`, and `:clang`. Homebrew will use this information to select a working compiler (if one is available).

### Specifying the download strategy explicitly

To use one of Homebrew’s built-in download strategies, specify the `:using =>` flag on a [`url`](https://www.rubydoc.info/github/Homebrew/brew/master/Formula#url-class_method) or [`head`](https://www.rubydoc.info/github/Homebrew/brew/master/Formula#head-class_method). For example:

```ruby
class Python3 < Formula
  homepage "https://www.python.org/"
  url "https://www.python.org/ftp/python/3.4.3/Python-3.4.3.tar.xz"
  sha256 "b5b3963533768d5fc325a4d7a6bd6f666726002d696f1d399ec06b043ea996b8"
  head "https://hg.python.org/cpython", :using => :hg
```

Homebrew offers anonymous download strategies.

| `:using` value | download strategy             |
|----------------|-------------------------------|
| `:bzr`         | `BazaarDownloadStrategy`      |
| `:curl`        | `CurlDownloadStrategy`        |
| `:cvs`         | `CVSDownloadStrategy`         |
| `:fossil`      | `FossilDownloadStrategy`      |
| `:git`         | `GitDownloadStrategy`         |
| `:hg`          | `MercurialDownloadStrategy`   |
| `:nounzip`     | `NoUnzipCurlDownloadStrategy` |
| `:post`        | `CurlPostDownloadStrategy`    |
| `:svn`         | `SubversionDownloadStrategy`  |
|----------------|-------------------------------|

If you need more control over the way files are downloaded and staged, you can create a custom download strategy and specify it using the [`url`](https://www.rubydoc.info/github/Homebrew/brew/master/Formula#url-class_method) method's `:using` option:

```ruby
class MyDownloadStrategy < SomeHomebrewDownloadStrategy
  def fetch
    # downloads output to `temporary_path`
  end
end

class Foo < Formula
  url "something", :using => MyDownloadStrategy
end
```

### Just moving some files

When your code in the install function is run, the current working directory is set to the extracted tarball.

So it is easy to just move some files:

```ruby
prefix.install "file1", "file2"
```

Or everything:

```ruby
prefix.install Dir["output/*"]
```

Generally we'd rather you were specific about what files or directories need to be installed rather than installing everything.

#### Variables for directory locations

| Name                  | Default                                        | Example                                           |
|-----------------------|------------------------------------------------|---------------------------------------------------|
| **`HOMEBREW_PREFIX`** | `/usr/local`                                   |                                                   |
| **`prefix`**          | `#{HOMEBREW_PREFIX}/Cellar/#{name}/#{version}` | `/usr/local/Cellar/foo/0.1`                       |
| **`opt_prefix`**      | `#{HOMEBREW_PREFIX}/opt/#{name}`               | `/usr/local/opt/foo`                              |
| **`bin`**             | `#{prefix}/bin`                                | `/usr/local/Cellar/foo/0.1/bin`                   |
| **`doc`**             | `#{prefix}/share/doc/foo`                      | `/usr/local/Cellar/foo/0.1/share/doc/foo`         |
| **`include`**         | `#{prefix}/include`                            | `/usr/local/Cellar/foo/0.1/include`               |
| **`info`**            | `#{prefix}/share/info`                         | `/usr/local/Cellar/foo/0.1/share/info`            |
| **`lib`**             | `#{prefix}/lib`                                | `/usr/local/Cellar/foo/0.1/lib`                   |
| **`libexec`**         | `#{prefix}/libexec`                            | `/usr/local/Cellar/foo/0.1/libexec`               |
| **`man`**             | `#{prefix}/share/man`                          | `/usr/local/Cellar/foo/0.1/share/man`             |
| **`man[1-8]`**        | `#{prefix}/share/man/man[1-8]`                 | `/usr/local/Cellar/foo/0.1/share/man/man[1-8]`    |
| **`sbin`**            | `#{prefix}/sbin`                               | `/usr/local/Cellar/foo/0.1/sbin`                  |
| **`share`**           | `#{prefix}/share`                              | `/usr/local/Cellar/foo/0.1/share`                 |
| **`pkgshare`**        | `#{prefix}/share/foo`                          | `/usr/local/Cellar/foo/0.1/share/foo`             |
| **`etc`**             | `#{HOMEBREW_PREFIX}/etc`                       | `/usr/local/etc`                                  |
| **`var`**             | `#{HOMEBREW_PREFIX}/var`                       | `/usr/local/var`                                  |
| **`buildpath`**       | A temporary directory somewhere on your system | `/private/tmp/[formula-name]-0q2b/[formula-name]` |

These can be used, for instance, in code such as

```ruby
bin.install Dir["output/*"]
```

to move binaries into their correct location into the Cellar, and

```ruby
man.mkpath
```

to create the directory structure for the manual page location.

To install man pages into specific locations, use `man1.install "foo.1", "bar.1"`, `man2.install "foo.2"`, etc.

Note that in the context of Homebrew, [`libexec`](https://www.rubydoc.info/github/Homebrew/brew/master/Formula#libexec-instance_method) is reserved for private use by the formula and therefore is not symlinked into `HOMEBREW_PREFIX`.

### Adding optional steps

If you want to add an [`option`](https://www.rubydoc.info/github/Homebrew/brew/master/Formula#option-class_method):

```ruby
class Yourformula < Formula
  ...
  option "with-ham", "Description of the option"
  option "without-spam", "Another description"

  depends_on "foo" => :optional  # will automatically add a with-foo option
  ...
```

And then to define the effects the [`option`](https://www.rubydoc.info/github/Homebrew/brew/master/Formula#option-class_method)s have:

```ruby
if build.with? "ham"
  # note, no "with" in the option name (it is added by the build.with? method)
end

if build.without? "ham"
  # works as you'd expect. True if `--without-ham` was given.
end
```

[`option`](https://www.rubydoc.info/github/Homebrew/brew/master/Formula#option-class_method) names should be prefixed with the words `with` or `without`. For example, an option to run a test suite should be named `--with-test` or `--with-check` rather than `--test`, and an option to enable a shared library `--with-shared` rather than `--shared` or `--enable-shared`.

**Note:** [`option`](https://www.rubydoc.info/github/Homebrew/brew/master/Formula#option-class_method)s that aren’t `build.with? ` or `build.without?` should be deprecated with [`deprecated_option`](https://www.rubydoc.info/github/Homebrew/brew/master/Formula#deprecated_option-class_method). See [`wget`](https://github.com/Homebrew/homebrew-core/blob/3f762b63c6fbbd49191ffdf58574d7e18937d93f/Formula/wget.rb#L27-L31) for an example.

We frown on [`option`](https://www.rubydoc.info/github/Homebrew/brew/master/Formula#option-class_method)s in Homebrew/homebrew-core as they are not tested by CI.

### File level operations

You can use the file utilities provided by Ruby's [`FileUtils`](https://www.ruby-doc.org/stdlib/libdoc/fileutils/rdoc/index.html). These are included in the [`Formula`](https://www.rubydoc.info/github/Homebrew/brew/master/Formula) class, so you do not need the `FileUtils.` prefix to use them.

When creating symlinks, take special care to ensure they are *relative* symlinks. This makes it easier to create a relocatable bottle. For example, to create a symlink in `bin` to an executable in `libexec`, use

```ruby
bin.install_symlink libexec/"name"
```

instead of:

```ruby
ln_s libexec/"name", bin
```

The symlinks created by [`install_symlink`](https://www.rubydoc.info/github/Homebrew/brew/master/Pathname#install_symlink-instance_method) are guaranteed to be relative. `ln_s` will only produce a relative symlink when given a relative path.

### Handling files that should persist over formula upgrades

For example, Ruby 1.9’s gems should be installed to `var/lib/ruby/` so that gems don’t need to be reinstalled when upgrading Ruby. You can usually do this with symlink trickery, or (ideally) a configure option.

Another example would be configuration files that should not be overwritten on package upgrades. If after installation you find that to-be-persisted configuration files are not copied but instead *symlinked* into `/usr/local/etc/` from the Cellar, this can often be rectified by passing an appropriate argument to the package’s configure script. That argument will vary depending on a given package’s configure script and/or Makefile, but one example might be: `--sysconfdir=#{etc}`

### launchd plist files

Homebrew provides two formula DSL methods for launchd plist files:

* [`plist_name`](https://www.rubydoc.info/github/Homebrew/brew/master/Formula#plist_name-instance_method) will return e.g. `homebrew.mxcl.<formula>`
* [`plist_path`](https://www.rubydoc.info/github/Homebrew/brew/master/Formula#plist_path-instance_method) will return e.g. `/usr/local/Cellar/foo/0.1/homebrew.mxcl.foo.plist`

## Updating formulae

Eventually a new version of the software will be released. In this case you should update the [`url`](https://www.rubydoc.info/github/Homebrew/brew/master/Formula#url-class_method) and [`sha256`](https://www.rubydoc.info/github/Homebrew/brew/master/Formula#sha256%3D-class_method). If a [`revision`](https://www.rubydoc.info/github/Homebrew/brew/master/Formula#revision%3D-class_method) line exists outside any `bottle do` block *and* the new release is stable rather than devel, it should be removed.

Leave the `bottle do ... end`  block as-is; our CI system will update it when we pull your change.

Check if the formula you are updating is a dependency for any other formulae by running `brew uses <formula>`. If it is a dependency, run `brew reinstall` for all the dependencies after it is installed and verify they work correctly.

## Style guide

Homebrew wants to maintain a consistent Ruby style across all formulae based on [Ruby Style Guide](https://github.com/styleguide/ruby). Other formulae may not have been updated to match this guide yet but all new ones should. Also:

* The order of methods in a formula should be consistent with other formulae (e.g.: `def install` goes before `def post_install`).
* An empty line is required before the `__END__` line.

## Troubleshooting for people writing new formulae

### Version detection fails

Homebrew tries to automatically determine the [`version`](https://www.rubydoc.info/github/Homebrew/brew/master/Formula#version-class_method) from the [`url`](https://www.rubydoc.info/github/Homebrew/brew/master/Formula#url-class_method) to avoid duplication. If the tarball has an unusual name you may need to manually assign the [`version`](https://www.rubydoc.info/github/Homebrew/brew/master/Formula#version-class_method).

### Bad makefiles

Not all projects have makefiles that will run in parallel so try to deparallelize by adding these lines to the `install` method:

```ruby
ENV.deparallelize
system "make"  # separate make and make install steps
system "make", "install"
```

If that fixes it, please open an [issue](https://github.com/Homebrew/homebrew-core/issues) so that we can fix it for everyone.

### Still won’t work?

Check out what MacPorts and Fink do:

```sh
brew search --macports foo
brew search --fink foo
```

## Superenv notes

`superenv` is our "super environment" that isolates builds by removing `/usr/local/bin` and all user `PATH`s that are not essential for the build. It does this because user `PATH`s are often full of stuff that breaks builds. `superenv` also removes bad flags from the commands passed to `clang`/`gcc` and injects others (for example all [`keg_only`](https://www.rubydoc.info/github/Homebrew/brew/master/Formula#keg_only-class_method) dependencies are added to the `-I` and `-L` flags).

## Fortran

Some software requires a Fortran compiler. This can be declared by adding `depends_on "gcc"` to a formula.

## How to start over (reset to upstream `master`)

Have you created a real mess in Git which stops you from creating a commit you want to submit to us? You might want to consider starting again from scratch. Your changes can be reset to the Homebrew `master` branch by running:

```sh
git checkout -f master
git reset --hard origin/master
```
