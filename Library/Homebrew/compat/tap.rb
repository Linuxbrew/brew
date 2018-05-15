module CaskTapMigrationExtension
  def parse_user_repo(*args)
    user, repo = super

    if user == "caskroom"
      user = "Homebrew"
      repo = "cask-#{repo}" unless repo == "cask"
    end

    [user, repo]
  end
end

class Tap
  class << self
    prepend CaskTapMigrationExtension
  end
end
