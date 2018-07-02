# Python

This page describes how Python is handled in Homebrew for users. See [Python for Formula Authors](Python-for-Formula-Authors.md) for advice on writing formulae to install packages written in Python.

Homebrew should work with any [CPython](https://stackoverflow.com/questions/2324208/is-there-any-difference-between-cpython-and-python) and defaults to the macOS system Python.

Homebrew provides formulae to brew 3.x and a more up-to-date Python 2.7.x.

**Important:** If you choose to install a Python which isn't either of these two (system Python or brewed Python), the Homebrew team cannot support any breakage that may occur.

## Python 3.x or Python 2.x
Homebrew provides one formula for Python 3.x (`python`) and another for Python 2.7.x (`python@2`).

The executables are organized as follows so that Python 2 and Python 3 can both be installed without conflict:
* `python3` points to Homebrew's Python 3.x (if installed)
* `python2` points to Homebrew's Python 2.7.x (if installed)
* `python` points to Homebrew's Python 2.7.x (if installed) otherwise the macOS system Python. Check out `brew info python` if you wish to add Homebrew's 3.x `python` to your `PATH`.
* `pip3` points to Homebrew's Python 3.x's pip (if installed)
* `pip` and `pip2` point to Homebrew's Python 2.7.x's pip (if installed)

([Wondering which one to choose?](https://wiki.python.org/moin/Python2orPython3))

## Setuptools, Pip, etc.
The Python formulae install [pip](http://www.pip-installer.org) (as `pip` or `pip2`) and [Setuptools](https://pypi.python.org/pypi/setuptools).

Setuptools can be updated via pip, without having to re-brew Python:

```sh
python -m pip install --upgrade setuptools
```

Similarly, pip can be used to upgrade itself via:

```sh
python -m pip install --upgrade pip
```

### Note on `pip install --user`
The normal `pip install --user` is disabled for brewed Python. This is because of a bug in distutils, because Homebrew writes a `distutils.cfg` which sets the package `prefix`.

A possible workaround (which puts executable scripts in `~/Library/Python/<X>.<Y>/bin`) is:

```sh
python -m pip install --user --install-option="--prefix=" <package-name>
```

## `site-packages` and the `PYTHONPATH`
The `site-packages` is a directory that contains Python modules (especially bindings installed by other formulae). Homebrew creates it here:

```sh
$(brew --prefix)/lib/pythonX.Y/site-packages
```

So, for Python 3.y.z, you'll find it at `/usr/local/lib/python3.y/site-packages`.

Python 3.y also searches for modules in:

- `/Library/Python/3.y/site-packages`
- `~/Library/Python/3.y/lib/python/site-packages`

Homebrew's `site-packages` directory is first created if (1) any Homebrew formula with Python bindings are installed, or (2) upon `brew install python`.

### Why here?
The reasoning for this location is to preserve your modules between (minor) upgrades or re-installations of Python. Additionally, Homebrew has a strict policy never to write stuff outside of the `brew --prefix`, so we don't spam your system.

## Homebrew-provided Python bindings
Some formulae provide Python bindings. Sometimes a `--with-python` or `--with-python@2` option has to be passed to `brew install` in order to build the Python bindings. (Check with `brew options <formula>`.)

**Warning!** Python may crash (see [Common Issues](Common-Issues.md)) if you `import <module>` from a brewed Python if you ran `brew install <formula_with_python_bindings>` against the system Python. If you decide to switch to the brewed Python, then reinstall all formulae with Python bindings (e.g. `pyside`, `wxwidgets`, `pygtk`, `pygobject`, `opencv`, `vtk` and `boost-python`).

## Policy for non-brewed Python bindings
These should be installed via `pip install <package>`. To discover, you can use `pip search` or <https://pypi.python.org/pypi>. (**Note:** System Python does not provide `pip`. Follow the [pip documentation](https://pip.readthedocs.io/en/stable/installing/#install-pip) to install it for your system Python if you would like it.)

## Brewed Python modules
For brewed Python, modules installed with `pip` or `python setup.py install` will be installed to the `$(brew --prefix)/lib/pythonX.Y/site-packages` directory (explained above). Executable Python scripts will be in `$(brew --prefix)/bin`.

The system Python may not know which compiler flags to set in order to build bindings for software installed in Homebrew so you may need to run:

```sh
CFLAGS=-I$(brew --prefix)/include LDFLAGS=-L$(brew --prefix)/lib pip install <package>
```

## Virtualenv
**WARNING:** When you `brew install` formulae that provide Python bindings, you should **not be in an active virtual environment**.

Activate the virtualenv *after* you've brewed, or brew in a fresh Terminal window.
Homebrew will still install Python modules into Homebrew's `site-packages` and *not* into the virtual environment's site-package.

Virtualenv has a `--system-site-packages` switch to allow "global" (i.e. Homebrew's) `site-packages` to be accessible from within the virtualenv.

## Why is Homebrew's Python being installed as a dependency?
Formulae that declare an unconditional dependency on the `"python"` or `"python@2"` formulae are bottled against Homebrew's Python 3.x or 2.7.x and require it to be installed.
