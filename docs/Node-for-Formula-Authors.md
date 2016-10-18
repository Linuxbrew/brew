# Node for formula authors

This document explains how to successfully use Node and npm in a Node module based Homebrew formula.

# Running `npm install`

Homebrew provides two helper methods in a `Language::Node` module, `std_npm_install_args` and `local_npm_install_args`. They both set up the correct environment for npm and return arguments for `npm install` for their specific use cases. Please use them instead of invoking `npm install` explicitly. The syntax for a standard Node module installation is:

```ruby
system "npm", "install", *Language::Node.std_npm_install_args(libexec)
```

where `libexec` is the destination prefix (usually the `libexec` variable).

# Download URL

If the Node module is also available on the npm registry, we prefer npm hosted release tarballs over GitHub (or elsewhere) hosted source tarballs. The advantages of these tarballs are that they doesn't include the files from the `.npmignore` (such as tests) resulting in a smaller download size and that a possibly transpilation step is already done (e.g. no need to compile CoffeeScript files as a build step).

The npm registry URLs have usually the format of:

```
https://registry.npmjs.org/<name>/-/<name>-<version>.tgz
```

Alternatively you could curl the JSON at `https://registry.npmjs.org/<name>` and look for the value of `versions[<version>].dist.tarball` for the correct tarball URL.

# Dependencies

Node modules, which are compatible with the latest Node version should declare a dependencies on the `node` formula.

```ruby
depends_on "node"
```

If your formula requires to be executed with an older Node version you must vendor this older Node version as done in the [`kibana` formula](https://github.com/Homebrew/homebrew-core/blob/c6202f91a129e2f994d904f299a308cc6fbd58e5/Formula/kibana.rb).

### Special requirements for native addons

If your node module is a native addon or has a native addon somewhere in it's dependency tree you have to declare an additional dependency. Since the compilation of the native addon results in a invocation of `node-gyp` we need an additional build time dependency on `:python` (because gyp depends on Python 2.7).

```ruby
depends_on :python => :build
```

Please also note, that such a formula would only be compatible with the same Node major version it originally was compiled with. This means that we need to revision every formula with a Node native addon with every major version bump of the `node` formula. To make sure we don't overlook your formula on a Node major version bump, write a meaningful test which would fail in such a case (invoked with an ABI incompatible Node version).

# Installation

Node modules should be installed to `libexec`. This prevents the Node modules from contaminating the global `node_modules`, which is important so that npm doesn't try to manage Homebrew-installed Node modules.

In the following we distinguish between 2 type of Node module using formulae:
* formulae for standard Node modules compatible with npm's global module format which should use [`std_npm_install_args`](#installing-global-style-modules-with-std_npm_install_args-to-libexec) (like [`azure-cli`](https://github.com/Homebrew/homebrew-core/blob/d93fe9ba3bcc9071b699c8da4e7d733518d3337e/Formula/azure-cli.rb) or [`autocode`](https://github.com/Homebrew/homebrew-core/blob/1a670a6269e1e07f86683c2d164977c9bd8a3fb6/Formula/autocode.rb)) and
* formulae were the `npm install` step is only one of multiple not exclusively Node related install steps (not compatible with npm's global module format) which have to use [`local_npm_install_args`](#installing-module-dependencies-locally-with-local_npm_install_args) (like [`elixirscript`](https://github.com/Homebrew/homebrew-core/blob/ec1e40d37e81af63122a354f0101c377f6a4e66d/Formula/elixirscript.rb) or [`kibana`](https://github.com/Homebrew/homebrew-core/blob/c6202f91a129e2f994d904f299a308cc6fbd58e5/Formula/kibana.rb))

Both methods have in common, that they are setting the correct environment for using npm inside Homebrew up and returning the arguments for invoking `npm install` for their specific use cases. This includes fixing an important edge case with the npm cache (Caused by Homebrew's redirection of `$HOME` during the build and test process) by using our own custom `npm_cache` inside `HOMEBREW_CACHE`, which would otherwise result in very long build times and high disk space usage.

To use them you have to require the Node language module at the beginning of your formula file with:

```ruby
require "language/node"
```

### Installing global style modules with `std_npm_install_args` to libexec

In your formula's `install` method, simply cd to the top level of your Node module if necessary and than use `system` to invoke `npm install` with `Language::Node.std_npm_install_args` like:

```ruby
system "npm", "install", *Language::Node.std_npm_install_args(libexec)
```

This will install your Node module in npm's global module style with a custom prefix to `libexec`. All your modules executable will be automatically resolved by npm into `libexec/"bin"` for you, which is not symlinked into Homebrew's prefix. We need to make sure these are installed. Do this with we need to symlink all executables to `bin` with:

```ruby
bin.install_symlink Dir["#{libexec}/bin/*"]
```

### Installing module dependencies locally with `local_npm_install_args`

In your formula's `install` method, do any installation steps which need to be done before the `npm install` step and than cd to the top level of the included Node module. Then, use `system` with `Language::Node.local_npm_install_args` to invoke `npm install` like:

```ruby
system "npm", "install", *Language::Node.local_npm_install_args
```

This will install all of your Node modules dependencies to your local build path. You can now continue with your build steps and take care of the installation into the Homebrew `prefix` by your own, following the [general Homebrew formula instructions](https://github.com/Homebrew/brew/blob/master/docs/Formula-Cookbook.md).

# Example

Installing a standard Node module based formula would look like this:

```ruby
require "language/node"

class Foo < Formula
  desc "..."
  homepage "..."
  url "https://registry.npmjs.org/foo/-/foo-1.4.2.tgz"
  sha256 "..."

  depends_on "node"
  # uncomment if there is a native addon inside the dependency tree
  # depends_on :python => :build

  def install
    system "npm", "install", *Language::Node.std_npm_install_args(libexec)
    bin.install_symlink Dir["#{libexec}/bin/*"]
  end

  test do
    # add a meaningful test here
  end
end
```

For examples using the `local_npm_install_args` method look at the  [`elixirscript`](https://github.com/Homebrew/homebrew-core/blob/ec1e40d37e81af63122a354f0101c377f6a4e66d/Formula/elixirscript.rb) or [`kibana`](https://github.com/Homebrew/homebrew-core/blob/c6202f91a129e2f994d904f299a308cc6fbd58e5/Formula/kibana.rb) formula.
