![Linuxbrew logo](https://linuxbrew.sh/images/linuxbrew-256x256.png)

# Linuxbrew (legacy repository)

## Migration to Homebrew

This repository has been deprecated and the content has been merged into https://github.com/Homebrew/brew.
User repositories have been automatically migrated to Homebrew since brew 1.9.4.

Install instructions and documentation can be found at https://docs.brew.sh/Linuxbrew.

You can also find us at:

- [@Linuxbrew on Twitter](https://twitter.com/Linuxbrew)
- [Linuxbrew/core on GitHub](https://github.com/Linuxbrew/homebrew-core)
- [Linuxbrew category](https://discourse.brew.sh/c/linuxbrew) of [Homebrew's Discourse](https://discourse.brew.sh)

## Features

The Homebrew package manager may be used on Linux and Windows 10, using [Windows Subsystem for Linux (WSL)](https://docs.microsoft.com/en-us/windows/wsl/about). Homebrew is referred to as Linuxbrew when running on Linux or Windows. It can be installed in your home directory, in which case it does not use *sudo*. Linuxbrew does not use any libraries provided by your host system, except *glibc* and *gcc* if they are new enough. Linuxbrew can install its own current versions of *glibc* and *gcc* for older distribution of Linux.

+ Can install software to your home directory and so does not require *sudo*
+ Install software not packaged by your host distribution
+ Install up-to-date versions of software when your host distribution is old
+ Use the same package manager to manage your macOS, Linux, and Windows systems
