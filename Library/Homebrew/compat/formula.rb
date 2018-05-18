class Formula
  module Compat
    def rake(*)
      odisabled "FileUtils#rake", "system \"rake\""
    end
  end

  prepend Compat
end
