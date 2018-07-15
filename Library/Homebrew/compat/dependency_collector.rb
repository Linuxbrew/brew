require "dependency_collector"

class DependencyCollector
  module Compat
    def parse_string_spec(spec, tags)
      odisabled "'depends_on ... => :run'" if tags.include?(:run)
      super
    end
  end

  prepend Compat
end
