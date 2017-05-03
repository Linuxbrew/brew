OFFICIAL_TAPS = %w[
  apache
  nginx
  php
  science
].freeze

OFFICIAL_CMD_TAPS = {
  "homebrew/bundle" => ["bundle"],
  (OS.mac? ? "homebrew/test-bot" : "linuxbrew/test-bot") => ["test-bot"],
  "homebrew/services" => ["services"],
}.freeze
