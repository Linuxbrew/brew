require "compat/cask/cask_loader"
require "compat/cask/cmd/--version"
require "compat/cask/cmd/cleanup"
require "compat/cask/cmd/search"
require "compat/cask/cache"
require "compat/cask/caskroom"
require "compat/cask/dsl"

module Cask
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
