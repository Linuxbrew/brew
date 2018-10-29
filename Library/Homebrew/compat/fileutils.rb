require "fileutils"

module FileUtils
  module Compat
    def ruby(*)
      odisabled "ruby", 'system "ruby"'
    end

    def mktemp(*)
      odisabled("FileUtils.mktemp", "mktemp")
    end
    module_function :mktemp
  end

  prepend Compat
end
