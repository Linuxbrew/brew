require "hbc/source/tapped_qualified"

class Hbc::Source::UntappedQualified < Hbc::Source::TappedQualified
  def self.me?(query)
    return if (tap = tap_for_query(query)).nil?

    tap.install
    tap.installed? && path_for_query(query).exist?
  end
end
