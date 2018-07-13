require "fileutils"

module FileUtils
  module Compat
    def mktemp(prefix = name, opts = {})
      # odeprecated("FileUtils.mktemp", "mktemp")
      Mktemp.new(prefix, opts).run do |staging|
        yield staging
      end
    end
    module_function :mktemp
  end

  prepend Compat
end
