require "fileutils"

module FileUtils
  module Compat
    def ruby(*args)
      odeprecated "ruby", 'system "ruby"'
      system RUBY_PATH, *args
    end

    def mktemp(prefix = name, opts = {})
      odeprecated("FileUtils.mktemp", "mktemp")
      Mktemp.new(prefix, opts).run do |staging|
        yield staging
      end
    end
    module_function :mktemp
  end

  prepend Compat
end
