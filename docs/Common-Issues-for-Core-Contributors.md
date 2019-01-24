# Common Issues for Core Contributors

## Overview

This is a page for maintainers to diagnose certain build errors.

## Issues

### `ld: internal error: atom not found in symbolIndex(__ZN10SQInstance3GetERK11SQObjectPtrRS0_) for architecture x86_64`

The exact atom may be different.

This can be caused by passing the obsolete `-s` flag to the linker and can be
fixed like [this](https://github.com/Homebrew/homebrew-core/commit/c4ad981d788b21a406a6efe7748f2922986919a8).
