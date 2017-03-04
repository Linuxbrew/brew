OFFICIAL_TAPS = %w[
  apache
  nginx
  php
  science
].freeze

OFFICIAL_CASK_TAPS = %w[
  cask
  versions
].freeze

OFFICIAL_CMD_TAPS = {
  "homebrew/bundle" => ["bundle"],
  "homebrew/test-bot" => ["test-bot"],
  "homebrew/services" => ["services"],
}.freeze
