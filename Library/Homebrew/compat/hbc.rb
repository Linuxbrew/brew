require "compat/hbc/cask_loader"
require "compat/hbc/cli/update"
require "compat/hbc/cache"
require "compat/hbc/caskroom"
require "compat/hbc/cli"
require "compat/hbc/dsl"

module Hbc
  class << self
    prepend(
      Module.new do
        def init
          Cache.delete_legacy_cache

          Caskroom.migrate_caskroom_from_repo_to_prefix
          Caskroom.migrate_legacy_caskroom

          super
        end
      end,
    )
  end
end
