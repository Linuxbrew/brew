OFFICIAL_TAPS = %w[
  apache
  completions
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
  x11
].freeze

OFFICIAL_CMD_TAPS = {
  "homebrew/bundle" => ["bundle"],
  (OS.mac? ? "homebrew/test-bot" : "linuxbrew/test-bot") => ["test-bot"],
  "homebrew/services" => ["services"],
}.freeze
