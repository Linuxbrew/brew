OFFICIAL_TAPS = %w[
  apache
  binary
  completions
  devel-only
  dupes
  emacs
  fuse
  games
  gui
  nginx
  php
  python
  science
  tex
  versions
  x11
].freeze

OFFICIAL_CMD_TAPS = {
  "caskroom/cask" => ["cask"],
  "homebrew/bundle" => ["bundle"],
  "homebrew/services" => ["services"],
}.freeze
