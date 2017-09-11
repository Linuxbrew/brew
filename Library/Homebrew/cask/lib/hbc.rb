require "hardware"
require "utils"

require "hbc/artifact"
require "hbc/audit"
require "hbc/auditor"
require "hbc/cache"
require "hbc/cask"
require "hbc/cask_loader"
require "hbc/caskroom"
require "hbc/checkable"
require "hbc/cli"
require "hbc/cask_dependencies"
require "hbc/caveats"
require "hbc/container"
require "hbc/download"
require "hbc/download_strategy"
require "hbc/exceptions"
require "hbc/installer"
require "hbc/locations"
require "hbc/macos"
require "hbc/pkg"
require "hbc/qualified_token"
require "hbc/scopes"
require "hbc/staged"
require "hbc/system_command"
require "hbc/topological_hash"
require "hbc/underscore_supporting_uri"
require "hbc/url"
require "hbc/utils"
require "hbc/verify"
require "hbc/version"

module Hbc
  include Locations
  include Scopes
  include Utils

  def self.init
    Cache.ensure_cache_exists
    Caskroom.ensure_caskroom_exists
  end
end
