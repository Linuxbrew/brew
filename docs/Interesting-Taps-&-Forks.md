# Interesting Taps & Forks

A Tap is homebrew-speak for a git repository containing extra formulae.
Homebrew has the capability to add (and remove) multiple taps to your local installation with the `brew tap` and `brew untap` command. Type `man brew` in your Terminal. The main repository https://github.com/Homebrew/homebrew-core, often called `homebrew/core`, is always built-in.

## Main Taps

*   [homebrew/apache](https://github.com/Homebrew/homebrew-apache): A tap for Apache modules, extending macOS's built-in Apache. These brews may require unconventional additional setup, as explained in the caveats.

*   [homebrew/boneyard](https://github.com/Homebrew/homebrew-boneyard): Formulae from other official taps, primarily (homebrew/core) are not deleted, they are moved here.

*   [homebrew/bundle](https://github.com/Homebrew/homebrew-bundle): Bundler for non-Ruby dependencies from Homebrew.

*   [homebrew/completions](https://github.com/Homebrew/homebrew-completions): Shell completion formulae.

*   [homebrew/dupes](https://github.com/Homebrew/homebrew-dupes): Need GDB or a newer Tk? System duplicates go here.

*   [homebrew/emacs](https://github.com/Homebrew/homebrew-emacs): A tap for Emacs packages.

*   [homebrew/games](https://github.com/Homebrew/homebrew-games): Game or gaming-emulation related formulae.

*   [homebrew/nginx](https://github.com/Homebrew/homebrew-nginx): Feature rich Nginx tap for modules.

*   [homebrew/php](https://github.com/Homebrew/homebrew-php): Repository for php-related formulae.

*   [homebrew/python](https://github.com/Homebrew/homebrew-python): A few Python formulae that do not build well with `pip` alone.

*   [homebrew/science](https://github.com/Homebrew/homebrew-science): A collection of scientific libraries and tools.

*   [homebrew/services](https://github.com/Homebrew/homebrew-services): A tool to start Homebrew formulae's plists with `launchctl`.

*   [homebrew/x11](https://github.com/Homebrew/homebrew-x11): Formulae with hard X11 dependencies.

`brew search` looks in these main taps as well as in [homebrew/core](https://github.com/Homebrew/homebrew-core). So don't worry about missing stuff. We will add other taps to the search as they become well maintained and popular.

You can be added as a maintainer for one of the Homebrew organization taps and aid the project! If you are interested write to our list: homebrew-discuss@googlegroups.com. We want your help!

## Other Interesting Taps

*   [InstantClientTap/instantclient](https://github.com/InstantClientTap/homebrew-instantclient): A tap for Oracle Instant Client. The packages need to be downloaded manually.

*   [besport/ocaml](https://github.com/besport/homebrew-ocaml): A tap for Ocaml libraries, though with caveats, it requires you install its customized ocaml formula. Perhaps a template for more work.

*   [osx-cross/avr](https://github.com/osx-cross/homebrew-avr): GNU AVR toolchain (Libc, compilers and other tools for Atmel MCUs, useful for Arduino hackers and AVR programmers).

*   [petere/postgresql](https://github.com/petere/homebrew-postgresql): Allows installing multiple PostgreSQL versions in parallel.

*   [titanous/gnuradio](https://github.com/titanous/homebrew-gnuradio):  GNU Radio and friends running on macOS.

## Interesting Forks

*   [mistydemeo/tigerbrew](https://github.com/mistydemeo/tigerbrew): Experimental Tiger PowerPC version

*   [Linuxbrew/brew](https://github.com/Linuxbrew/brew): Experimental Linux version

## Technical Details

Your taps are git repositories located at `$(brew --repository)/Library/Taps`.
