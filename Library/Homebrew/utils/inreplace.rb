module Utils
  class InreplaceError < RuntimeError
    def initialize(errors)
      super errors.inject("inreplace failed\n") do |s, (path, errs)|
        s << "#{path}:\n" << errs.map { |e| "  #{e}\n" }.join
      end
    end
  end

  module Inreplace
    # Sometimes we have to change a bit before we install. Mostly we
    # prefer a patch but if you need the `prefix` of this formula in the
    # patch you have to resort to `inreplace`, because in the patch
    # you don't have access to any var defined by the formula. Only
    # HOMEBREW_PREFIX is available in the embedded patch.
    # inreplace supports regular expressions.
    # <pre>inreplace "somefile.cfg", /look[for]what?/, "replace by #{bin}/tool"</pre>
    def inreplace(paths, before = nil, after = nil, audit_result = true)
      errors = {}

      Array(paths).each do |path|
        s = File.open(path, "rb", &:read).extend(StringInreplaceExtension)

        if before.nil? && after.nil?
          yield s
        else
          after = after.to_s if after.is_a? Symbol
          s.gsub!(before, after, audit_result)
        end

        errors[path] = s.errors unless s.errors.empty?

        Pathname(path).atomic_write(s)
      end

      raise InreplaceError, errors unless errors.empty?
    end
    module_function :inreplace
  end
end
