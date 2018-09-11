# Acceptable Formulae

Some formulae should not go in
[homebrew/core](https://github.com/Homebrew/homebrew-core). But there are
additional [Interesting Taps and Forks](Interesting-Taps-and-Forks.md) and anyone can start their
own!

### Dupes in `homebrew/core`
We now accept stuff that comes with macOS as long as it uses `keg_only :provided_by_macos` to be keg-only by default.

### Versioned formulae in `homebrew/core`
We now accept versioned formulae as long as they [meet the requirements](Versions.md).

### We don’t like tools that upgrade themselves
Software that can upgrade itself does not integrate well with Homebrew's own
upgrade functionality. The self-update functionality should be disabled (if possible without complicating the formula).

### We don’t like install-scripts that download unversioned things
We don't like install scripts that are pulling from the `master` branch of Git repositories or unversioned, unchecksummed tarballs. These should use `resource` blocks with specific revisions or checksummed tarballs instead. Note that we now allow tools like `cargo`, `gem` and `pip` to download specifically versioned libraries during installation.

### We don’t like binary formulae
Our policy is that formulae in the core tap
([homebrew/core](https://github.com/Homebrew/homebrew-core)) must be open-source
and either built from source or produce cross-platform binaries (e.g. Java, Mono).
Binary-only formulae should go to
[Homebrew Cask](https://github.com/Homebrew/homebrew-cask).

### Stable versions
Formulae in the core repository must have a stable version tagged by
the upstream project. Tarballs are preferred to Git checkouts, and
tarballs should include the version in the filename whenever possible.

We don’t accept software without a tagged version because they regularly break
due to upstream changes and we can’t provide [bottles](Bottles.md) for them.

### Niche (or self-submitted) stuff
The software in question must:

* be maintained (i.e. the last release wasn't ages ago, it works without patching on all supported macOS releases and has no outstanding, unpatched security vulnerabilities)
* be known
* be stable (e.g. not declared "unstable" or "beta" by upstream)
* be used
* have a homepage

We will reject formulae that seem too obscure, partly because they won’t
get maintained and partly because we have to draw the line somewhere.

We frown on authors submitting their own work unless it is very popular.

Don’t forget Homebrew is all Git underneath!
[Maintain your own tap](How-to-Create-and-Maintain-a-Tap.md) if you have to!

There may be exceptions to these rules in the main repository; we may
include things that don't meet these criteria or reject things that do.
Please trust that we need to use our discretion based on our experience
running a package manager.

### Stuff that builds an `.app`
Don’t make your formula build an `.app` (native macOS Application); we
don’t want those things in Homebrew. Encourage upstream projects to build and support a `.app` that can be distributed by [Homebrew Cask](https://github.com/Homebrew/homebrew-cask) (and used without it, too).

### Stuff that builds a GUI by default (but doesn't have to)
Make it build a command-line tool or a library by default and, if the GUI is useful and would be widely used, add an option to build the GUI. Don't offer an option for multiple GUI backends e.g. X11 is a bad user experience for GUIs on macOS.

### Stuff that doesn't build with the latest, stable Xcode's Clang
Clang is the default C/C++ compiler on macOS (and has been for a long time). Software that doesn't build with it hasn't been adequately ported to macOS.

### Stuff that requires heavy manual pre/post-install intervention
We're a package manager so we want to do things like resolve dependencies and setup applications for our users. If things require too much manual intervention then they aren't useful in a package manager.

### Sometimes there are exceptions
Even if all criteria are met we may not accept the formula.
Documentation tends to lag behind current decision-making. Although some
rejections may seem arbitrary or strange they are based on years of
experience making Homebrew work acceptably for our users.
