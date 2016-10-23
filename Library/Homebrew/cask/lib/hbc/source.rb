require "hbc/source/gone"
require "hbc/source/path_slash_required"
require "hbc/source/path_slash_optional"
require "hbc/source/tapped_qualified"
require "hbc/source/untapped_qualified"
require "hbc/source/tapped"
require "hbc/source/uri"

module Hbc
  module Source
    def self.sources
      [
        URI,
        PathSlashRequired,
        TappedQualified,
        UntappedQualified,
        Tapped,
        PathSlashOptional,
        Gone,
      ]
    end

    def self.for_query(query)
      odebug "Translating '#{query}' into a valid Cask source"
      raise CaskUnavailableError, query if query.to_s =~ /^\s*$/
      source = sources.find do |s|
        odebug "Testing source class #{s}"
        s.me?(query)
      end
      raise CaskUnavailableError, query unless source
      odebug "Success! Using source class #{source}"
      resolved_cask_source = source.new(query)
      odebug "Resolved Cask URI or file source to '#{resolved_cask_source}'"
      resolved_cask_source
    end
  end
end
