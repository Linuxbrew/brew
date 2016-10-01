require "hbc/source/tapped"

class Hbc::Source::TappedQualified < Hbc::Source::Tapped
  def self.me?(query)
    return if (tap = tap_for_query(query)).nil?

    tap.installed? && path_for_query(query).exist?
  end

  def self.tap_for_query(query)
    qualified_token = Hbc::QualifiedToken.parse(query)
    return if qualified_token.nil?

    user, repo = qualified_token[0..1]
    Tap.fetch(user, repo)
  end

  def self.path_for_query(query)
    user, repo, token = Hbc::QualifiedToken.parse(query)
    Tap.fetch(user, repo).cask_dir.join(token.sub(%r{(\.rb)?$}i, ".rb"))
  end
end
