# Python for Formula Authors

This document explains how to successfully use Python in a Homebrew formula.

Homebrew draws a distinction between Python **applications** and Python **libraries**. The difference is that users generally do not care that applications are written in Python; it is unusual that a user would expect to be able to `import foo` after installing an application. Examples of applications are [`ansible`](https://github.com/Homebrew/homebrew-core/blob/master/Formula/ansible.rb) and [`jrnl`](https://github.com/Homebrew/homebrew-core/blob/master/Formula/jrnl.rb).

Python libraries exist to be imported by other Python modules; they are often dependencies of Python applications. They are usually no more than incidentally useful from a Terminal.app command line. Examples of libraries are [`py2cairo`](https://github.com/Homebrew/homebrew-core/blob/master/Formula/py2cairo.rb) and the bindings that are installed by [`protobuf --with-python`](https://github.com/Homebrew/homebrew-core/blob/master/Formula/protobuf.rb).

Bindings are a special case of libraries that allow Python code to interact with a library or application implemented in another language.

Homebrew is happy to accept applications that are built in Python, whether the apps are available from PyPI or not. Homebrew generally won't accept libraries that can be installed correctly with `pip install foo`. Bindings may be installed for packages that provide them, especially if equivalent functionality isn't available through pip.

Applications should unconditionally bundle all of their Python-language dependencies and libraries and should install any unsatisfied dependencies; these strategies are discussed in depth in the following sections.

## Applications

### Python declarations

Applications that are compatible with Python 2 **should** use the Apple-provided system Python in `/usr/bin` on systems that provide Python 2.7. To do this, declare:

```ruby
depends_on :python if MacOS.version <= :snow_leopard
```

No explicit Python dependency is needed on recent OS versions since `/usr/bin` is always in `PATH` for Homebrew formulae; on Leopard and older, the python in `PATH` is used if it's at least version 2.7, or else Homebrew's python is installed.

Formulae for apps that require Python 3 **should** declare an unconditional dependency on `:python3`, which will cause the formula to use the first python3 discovered in `PATH` at install time (or install Homebrew's if there isn't one). These apps **must** work with the current Homebrew python3 formula.

### Installing

Applications should be installed into a Python [virtualenv](https://virtualenv.pypa.io/en/stable/) environment rooted in `libexec`. This prevents the app's Python modules from contaminating the system site-packages and vice versa.

All of the Python module dependencies of the application (and their dependencies, recursively) should be declared as `resource`s in the formula and installed into the virtualenv, as well. Each dependency should be explicitly specified; please do not rely on `setup.py` or `pip` to perform automatic dependency resolution, for the [reasons described here](Acceptable-Formulae.md#we-dont-like-install-scripts-that-download-things).

You can use [homebrew-pypi-poet](https://pypi.python.org/pypi/homebrew-pypi-poet) to help you write resource stanzas. To use it, set up a virtualenv and install your package and all its dependencies. Then, `pip install homebrew-pypi-poet` into the same virtualenv. Running `poet some_package` will generate the necessary resource stanzas. You can do this like:

```sh
# Install virtualenvwrapper
brew install python
python -m pip install virtualenvwrapper
source $(brew --prefix)/bin/virtualenvwrapper.sh

# Set up a temporary virtual environment
mktmpenv

# Install the package of interest as well as homebrew-pypi-poet
pip install some_package homebrew-pypi-poet
poet some_package

# Destroy the temporary virtualenv you just created
deactivate
```

Homebrew provides helper methods for instantiating and populating virtualenvs. You can use them by putting `include Language::Python::Virtualenv` on the `Formula` class definition, above `def install`.

For most applications, all you will need to write is:

```ruby
def install
  virtualenv_install_with_resources
end
```

This is exactly the same as writing:

```ruby
def install
  # Create a virtualenv in `libexec`. If your app needs Python 3, make sure that
  # `depends_on :python3` is declared, and use `virtualenv_create(libexec, "python3")`.
  venv = virtualenv_create(libexec)
  # Install all of the resources declared on the formula into the virtualenv.
  venv.pip_install resources
  # `pip_install_and_link` takes a look at the virtualenv's bin directory
  # before and after installing its argument. New scripts will be symlinked
  # into `bin`. `pip_install_and_link buildpath` will install the package
  # that the formula points to, because buildpath is the location where the
  # formula's tarball was unpacked.
  venv.pip_install_and_link buildpath
end
```

### Example

Installing a formula with dependencies will look like this:

```ruby
class Foo < Formula
  url "..."

  resource "six" do
    url "https://pypi.python.org/packages/source/s/six/six-1.9.0.tar.gz"
    sha256 "e24052411fc4fbd1f672635537c3fc2330d9481b18c0317695b46259512c91d5"
  end

  resource "parsedatetime" do
    url "https://pypi.python.org/packages/source/p/parsedatetime/parsedatetime-1.4.tar.gz"
    sha256 "09bfcd8f3c239c75e77b3ff05d782ab2c1aed0892f250ce2adf948d4308fe9dc"
  end

  include Language::Python::Virtualenv

  def install
    virtualenv_install_with_resources
  end
end
```

You can also use the more verbose form and request that specific resources be installed:

```ruby
def install
  venv = virtualenv_create(libexec)
  %w[six parsedatetime].each do |r|
    venv.pip_install resource(r)
  end
  venv.pip_install_and_link buildpath
end
```

in case you need to do different things for different resources.

## Bindings

Build bindings with system Python by default (don't add an option) and they should be usable with any binary-compatible Python. If that isn't the case, it's an upstream bug; [here's some advice for resolving it](http://blog.tim-smith.us/2015/09/python-extension-modules-os-x/).

To add bindings for Python 3, please add `depends_on :python3 => :optional` and make the bindings conditional on `build.with?("python3")`.

### Dependencies

Bindings should follow the same advice for Python module dependencies as libraries; see below for more.

### Installing bindings

If the bindings are installed by invoking a `setup.py`, do something like:

```ruby
cd "source/python" do
  system "python", *Language::Python.setup_install_args(prefix)
end
```

If the configure script takes a `--with-python` flag, it usually will not need extra help finding Python.

If the `configure` and `make` scripts do not want to install into the Cellar, sometimes you can:

1. Call `./configure --without-python` (or a similar named option)
1. `cd` into the directory containing the Python bindings
1. Call `setup.py` with `system` and `Language::Python.setup_install_args` (as described above)

Sometimes we have to `inreplace` a `Makefile` to use our prefix for the Python bindings. (`inreplace` is one of Homebrew's helper methods, which greps and edits text files on-the-fly.)

## Libraries

### Python declarations

Python 2 libraries do not need a `depends_on :python` declaration; they will be built with system Python, but should still be usable with any other Python 2.7. If this is not the case, it is an upstream bug; [here is some advice for resolving it](http://blog.tim-smith.us/2015/09/python-extension-modules-os-x/). Libraries built for Python 3 should include `depends_on :python3`, which will bottle against Homebrew's python3, and use the first python3 discovered in `PATH` at build time when installing from source with `brew install --build-from-source`. If a library supports both Python 2.x and Python 3.x, the `:python3` dependency should be `:optional`. Python 2.x libraries must function when they are installed against either the system Python or Homebrew Python.

### Installing

Libraries may be installed to `libexec` and added to `sys.path` by writing a .pth file (named like "homebrew-foo.pth") to the `prefix` site-packages. This simplifies the ensuing drama if `pip` is accidentally used to upgrade a Homebrew-installed package and prevents the accumulation of stale .pyc files in Homebrew's site-packages.

Most formulae presently just install to `prefix`.

### Dependencies

The dependencies of libraries must be installed so that they are importable. To minimize the potential for linking conflicts, dependencies should be installed to `libexec/"vendor"` and added to `sys.path` by writing a second .pth file (named like "homebrew-foo-dependencies.pth") to the `prefix` site-packages.

The [matplotlib](https://github.com/Homebrew/homebrew-science/blob/master/matplotlib.rb) formula in [homebrew/science](https://github.com/Homebrew/homebrew-science) deploys this strategy.

## Further down the rabbit hole

Additional commentary that explains why Homebrew does some of the things it does.

### setuptools vs. distutils vs. pip

Distutils is a module in the Python standard library that provides developers a basic package management API. Setuptools is a module distributed outside the standard library that extends distutils. It is a convention that Python packages provide a `setup.py` that calls the `setup()` function from either distutils or setuptools.

Setuptools provides the `easy_install` command, which is an end-user package management tool that fetches and installs packages from PyPI, the Python Package Index. `pip` is another, newer end-user package management tool, which is also provided outside the standard library. While pip supplants `easy_install`, pip does not replace the other functionality of the setuptools module.

Distutils and pip use a "flat" installation hierarchy that installs modules as individual files under site-packages while `easy_install` installs zipped eggs to site-packages instead.

Distribute (not to be confused with distutils) is an obsolete fork of setuptools. Distlib is a package maintained outside the standard library which is used by pip for some low-level packaging operations and is not relevant to most `setup.py` users.

### Running `setup.py`

In the event that a formula needs to interact with `setup.py` instead of calling `pip`, Homebrew provides a helper method, `Language::Python.setup_install_args`, which returns useful arguments for invoking `setup.py`. Your formula should use this instead of invoking `setup.py` explicitly. The syntax is:

```ruby
system "python", *Language::Python.setup_install_args(prefix)
```

where `prefix` is the destination prefix (usually `libexec` or `prefix`).

### What is `--single-version-externally-managed`?

`--single-version-externally-managed` ("SVEM") is a setuptools-only [argument to `setup.py install`](https://setuptools.readthedocs.io/en/latest/setuptools.html?#install-run-easy-install-or-old-style-installation). The primary effect of SVEM is to use distutils to perform the install instead of using setuptools' `easy_install`.

`easy_install` does a few things that we need to avoid:

* fetches and installs dependencies
* upgrades dependencies in `sys.path` in-place
* writes .pth and site.py files which aren't useful for us and cause link conflicts

Setuptools requires that SVEM is used in conjunction with `--record`, which provides a list of files that can later be used to uninstall the package. We don't need or want this because Homebrew can manage uninstallation but since setuptools demands it we comply. The Homebrew convention is to call the record file "installed.txt".

Detecting whether a `setup.py` uses `setup()` from setuptools or distutils is difficult, but we always need to pass this flag to setuptools-based scripts. `pip` faces the same problem that we do and forces `setup()` to use the setuptools version by loading a shim around `setup.py` that imports setuptools before doing anything else. Since setuptools monkey-patches distutils and replaces its `setup` function, this provides a single, consistent interface. We have borrowed this code and use it in `Language::Python.setup_install_args`.

### `--prefix` vs `--root`

`setup.py` accepts a slightly bewildering array of installation options. The correct switch for Homebrew is `--prefix`, which automatically sets the `--install-foo` family of options using sane POSIX-y values.

`--root` [is used](https://mail.python.org/pipermail/distutils-sig/2010-November/017099.html) when installing into a prefix that will not become part of the final installation location of the files, like when building a .rpm or binary distribution. When using a `setup.py`-based setuptools, `--root` has the side effect of activating `--single-version-externally-managed`. It is not safe to use `--root` with an empty `--prefix` because the `root` is removed from paths when byte-compiling modules.

It is probably safe to use `--prefix` with `--root=/`, which should work with either setuptools or distutils-based `setup.py`'s but is kinda ugly.

### `pip` vs. `setup.py`

[PEP 453](http://legacy.python.org/dev/peps/pep-0453/#recommendations-for-downstream-distributors) makes a recommendation to downstream distributors (us) that sdist tarballs should be installed with `pip` instead of by invoking `setup.py` directly. We do not do this because Apple's Python distribution does not include pip, so we can't assume that pip is available. We could do something clever to work around Apple's piplessness but the value proposition is not yet clear.
