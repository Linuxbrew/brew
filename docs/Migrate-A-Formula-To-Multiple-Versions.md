# Migrate a Formula to Multiple Versions
## Migrating an existing formula to multiple versions

In separate pull-requests:

1. [Rename the formula](Rename-A-Formula.md) from e.g. `boost.rb` to e.g. `boost@1.61.rb` and, in the same pull request, add an alias named `boost`. This should not require any `revision`ing or significant formula modification beyond the formula name.
2. Add the new version formula e.g. `boost@1.62.rb`
3. Tap authors should have their `depends_on "boost"` updated to `depends_on "boost@1.61"` or `depends_on "boost@1.62"`.
4. Modify the `boost` alias to point to `boost@1.62.rb`. Any formulae that need the old version of `boost` should have their `depends_on "boost"` to be updated to `depends_on "boost@1.61"`.
5. When `boost@1.62` has two major/minor versions newer than it (e.g. `boost@1.64`) then consider removing `boost@1.62.rb` and anything that depends on it.

## Upgrading a multiple version formula

In separate pull-requests:

1. Add the new version formula e.g. `boost@1.63.rb`
2. Modify the `boost` alias to point to `boost@1.63.rb`. Any formulae that need the old version of `boost` should have their `depends_on "boost"` to be updated to `depends_on "boost@1.62"`.
3. When `boost@1.63` has two major/minor versions newer than it (e.g. `boost@1.65`) then consider removing `boost@1.63.rb` and anything that depends on it.

## Importing a homebrew/versions formula into homebrew/core

In separate pull-requests:

1. [Migrate the formula](Migrating-A-Formula-To-A-Tap.md) from Homebrew/homebrew-versions to Homebrew/homebrew-core with the same, old name e.g. `boost160.rb`.
2. [Rename the formula](Rename-A-Formula.md) from e.g. `boost160.rb` to e.g. `boost@1.60.rb`. This should not require any `revision`ing or significant formula modification beyond the formula name.
3. Tap authors should have their `depends_on "boost160"` updated to `depends_on "boost@1.60"`.
5. When `boost@1.60` has two major/minor versions newer than it (e.g. `boost@1.62`) then consider removing `boost@1.60.rb` and anything that depends on it.
