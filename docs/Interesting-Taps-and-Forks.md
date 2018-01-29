# Interesting Taps & Forks

A _tap_ is homebrew-speak for a Git repository containing extra formulae.
Homebrew has the capability to add (and remove) multiple taps to your local installation with the `brew tap` and `brew untap` commands. Type `man brew` in your Terminal. The main repository [https://github.com/Homebrew/homebrew-core](https://github.com/Homebrew/homebrew-core), often called `homebrew/core`, is always built-in.

## Main taps

*   [homebrew/php](https://github.com/Homebrew/homebrew-php): Repository for PHP-related formulae.

`brew search` looks in these taps as well as in [homebrew/core](https://github.com/Homebrew/homebrew-core) so don't worry about missing stuff.

You can be added as a maintainer for one of the Homebrew organization taps and aid the project! If you are interested please feel free to ask in an issue or pull request after submitting multiple high-quality pull requests. We want your help!

## Other interesting taps

*   [denji/nginx](https://github.com/denji/homebrew-nginx): A tap for NGINX modules, intended for its `nginx-full` formula which includes more module options.

*   [InstantClientTap/instantclient](https://github.com/InstantClientTap/homebrew-instantclient): A tap for Oracle Instant Client. The packages need to be downloaded manually.

*   [osx-cross/avr](https://github.com/osx-cross/homebrew-avr): GNU AVR toolchain (Libc, compilers and other tools for Atmel MCUs, useful for Arduino hackers and AVR programmers).

*   [petere/postgresql](https://github.com/petere/homebrew-postgresql): Allows installing multiple PostgreSQL versions in parallel.

*   [titanous/gnuradio](https://github.com/titanous/homebrew-gnuradio):  GNU Radio and friends running on macOS.

*   [dunn/emacs](https://github.com/dunn/homebrew-emacs): A tap for Emacs packages.

*   [sidaf/pentest](https://github.com/sidaf/homebrew-pentest): Tools for penetration testing.

*   [osrf/simulation](https://github.com/osrf/homebrew-simulation): Tools for robotics simulation.

*   [brewsci/bio](https://github.com/brewsci/homebrew-bio): Bioinformatics formulae.

*   [brewsci/science](https://github.com/brewsci/homebrew-science): Software tailored to scientific endeavours.

## Interesting forks

*   [mistydemeo/tigerbrew](https://github.com/mistydemeo/tigerbrew): Experimental Tiger PowerPC version

*   [Linuxbrew/brew](https://github.com/Linuxbrew/brew): Experimental Linux version

## Technical details

Your taps are Git repositories located at `$(brew --repository)/Library/Taps`.
