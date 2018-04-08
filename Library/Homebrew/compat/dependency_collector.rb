require "dependency_collector"

class DependencyCollector
  module Compat
    # Define the languages that we can handle as external dependencies.
    LANGUAGE_MODULES = Set[
      :lua, :lua51, :perl, :python, :python3, :ruby
    ].freeze

    def parse_string_spec(spec, tags)
      if (tag = tags.first) && LANGUAGE_MODULES.include?(tag)
        odisabled "'depends_on ... => #{tag.inspect}'"
      end

      if tags.include?(:run)
        odeprecated "'depends_on ... => :run'"
      end

      super
    end

    def parse_symbol_spec(spec, tags)
      case spec
      when :clt
        odisabled "'depends_on :clt'"
      when :tex
        odisabled "'depends_on :tex'"
      when :libltdl
        output_disabled(spec, "libtool")
      when :apr
        output_disabled(spec, "apr-util")
      when :fortran
        output_disabled(spec, "gcc")
      when :gpg
        output_disabled(spec, "gnupg")
      when :hg
        output_disabled(spec, "mercurial")
      when :mpi
        output_disabled(spec, "open-mpi")
      when :python, :python2
        output_disabled(spec, "python@2")
      when :python3
        output_disabled(spec, "python")
      when :ant, :autoconf, :automake, :bsdmake, :cairo, :emacs, :expat,
           :fontconfig, :freetype, :libtool, :libpng, :mysql, :perl, :pixman,
           :postgresql, :rbenv, :ruby
        output_disabled(spec)
      else
        super
      end
    end

    private

    def output_disabled(dependency, new_dependency = dependency)
      odisabled "'depends_on :#{dependency}'",
                "'depends_on \"#{new_dependency}\"'"
    end
  end

  prepend Compat
end
