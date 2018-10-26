require 'rubocop'

require 'rubocops/cask/constants/cask_method_names'
require 'rubocops/cask/constants/stanza'

require 'rubocops/cask/ast/stanza'
require 'rubocops/cask/ast/cask_header'
require 'rubocops/cask/ast/cask_block'
require 'rubocops/cask/extend/string'
require 'rubocops/cask/extend/node'
require 'rubocops/cask/mixin/cask_help'
require 'rubocops/cask/mixin/on_homepage_stanza'
require 'rubocops/cask/homepage_matches_url'
require 'rubocops/cask/homepage_url_trailing_slash'
require 'rubocops/cask/no_dsl_version'
require 'rubocops/cask/stanza_order'
require 'rubocops/cask/stanza_grouping'

module RuboCop
  module Cask
    DEFAULT_CONFIG = File.expand_path('cask/config/default.yml', __dir__)
  end

  ConfigLoader.default_configuration = ConfigLoader.merge_with_default(
    ConfigLoader.load_file(Cask::DEFAULT_CONFIG),
    Cask::DEFAULT_CONFIG
  )
end
