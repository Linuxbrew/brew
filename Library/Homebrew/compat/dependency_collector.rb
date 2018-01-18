require "dependency_collector"

class DependencyCollector
  module Compat
    # Define the languages that we can handle as external dependencies.
    LANGUAGE_MODULES = Set[
      :lua, :lua51, :perl, :python, :python3, :ruby
    ].freeze

    def parse_string_spec(spec, tags)
      if (tag = tags.first) && LANGUAGE_MODULES.include?(tag)
        odeprecated "'depends_on ... => #{tag.inspect}'"
        LanguageModuleRequirement.new(tag, spec, tags[1])
      else
        super
      end
    end

    def parse_symbol_spec(spec, tags)
      case spec
      when :clt
        odeprecated "'depends_on :clt'"
      when :tex
        odeprecated "'depends_on :tex'"
        TeXRequirement.new(tags)
      when :autoconf, :automake, :bsdmake, :libtool
        output_deprecation(spec)
        autotools_dep(spec, tags)
      when :cairo, :fontconfig, :freetype, :libpng, :pixman
        output_deprecation(spec)
        Dependency.new(spec.to_s, tags)
      when :ant, :expat
        output_deprecation(spec)
        Dependency.new(spec.to_s, tags)
      when :libltdl
        tags << :run
        output_deprecation("libtool")
        Dependency.new("libtool", tags)
      when :apr
        output_deprecation(spec, "apr-util")
        Dependency.new("apr-util", tags)
      when :fortran
        output_deprecation(spec, "gcc")
        Dependency.new("gcc", tags)
      when :gpg
        output_deprecation(spec, "gnupg")
        Dependency.new("gnupg", tags)
      when :hg
        output_deprecation(spec, "mercurial")
        Dependency.new("mercurial", tags)
      when :mpi
        output_deprecation(spec, "open-mpi")
        Dependency.new("open-mpi", tags)
      when :python, :python2
        output_deprecation(spec, "python")
        Dependency.new("python", tags)
      when :python3
        output_deprecation(spec, "python3")
        Dependency.new("python3", tags)
      when :emacs, :mysql, :perl, :postgresql, :rbenv, :ruby
        output_deprecation(spec)
        Dependency.new(spec, tags)
      else
        super
      end
    end

    private

    def autotools_dep(spec, tags)
      tags << :build unless tags.include? :run
      Dependency.new(spec.to_s, tags)
    end

    def output_deprecation(dependency, new_dependency = dependency)
      odeprecated "'depends_on :#{dependency}'",
                  "'depends_on \"#{new_dependency}\"'"
    end
  end

  prepend Compat
end
