require "compat/hbc/cask_loader"
require "compat/hbc/cli/search"
require "compat/hbc/cache"
require "compat/hbc/caskroom"
require "compat/hbc/dsl"

module Hbc
  class << self
    module Compat
      def init
        Cache.delete_legacy_cache

        Caskroom.migrate_caskroom_from_repo_to_prefix
        Caskroom.migrate_legacy_caskroom

        super
      end
    end

    prepend Compat
  end
end
