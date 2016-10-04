OFFICIAL_TAPS = %w[
  apache
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
  "homebrew/bundle" => ["bundle"],
  "homebrew/test-bot" => ["test-bot"],
  "homebrew/services" => ["services"],
}.freeze
