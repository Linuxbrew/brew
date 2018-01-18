require "dependency_collector"

class DependencyCollector
  alias _parse_string_spec parse_string_spec

  # Define the languages that we can handle as external dependencies.
  LANGUAGE_MODULES = Set[
    :lua, :lua51, :perl, :python, :python3, :ruby
  ].freeze

  def parse_string_spec(spec, tags)
    if (tag = tags.first) && LANGUAGE_MODULES.include?(tag)
      odeprecated "'depends_on :#{tag}'"
      LanguageModuleRequirement.new(tag, spec, tags[1])
    else
      _parse_string_spec(spec, tags)
    end
  end

  alias _parse_symbol_spec parse_symbol_spec

  def parse_symbol_spec(spec, tags)
    case spec
    when :clt
      odeprecated "'depends_on :clt'"
    when :tex
      odeprecated "'depends_on :tex'"
      TeXRequirement.new(tags)
    when :autoconf, :automake, :bsdmake, :libtool
      output_deprecation(spec, tags)
      autotools_dep(spec, tags)
    when :cairo, :fontconfig, :freetype, :libpng, :pixman
      output_deprecation(spec, tags)
      Dependency.new(spec.to_s, tags)
    when :ant, :expat
      # output_deprecation(spec, tags)
      Dependency.new(spec.to_s, tags)
    when :libltdl
      tags << :run
      output_deprecation("libtool", tags)
      Dependency.new("libtool", tags)
    when :apr
      output_deprecation(spec, tags, "apr-util")
      Dependency.new("apr-util", tags)
    when :fortran
      # output_deprecation(spec, tags, "gcc")
      FortranRequirement.new(tags)
    when :gpg
      # output_deprecation(spec, tags, "gnupg")
      GPG2Requirement.new(tags)
    when :hg
      # output_deprecation(spec, tags, "mercurial")
      MercurialRequirement.new(tags)
    when :mpi
      # output_deprecation(spec, tags, "open-mpi")
      MPIRequirement.new(*tags)
    when :emacs
      # output_deprecation(spec, tags)
      EmacsRequirement.new(tags)
    when :mysql
      # output_deprecation(spec, tags)
      MysqlRequirement.new(tags)
    when :perl
      # output_deprecation(spec, tags)
      PerlRequirement.new(tags)
    when :postgresql
      # output_deprecation(spec, tags)
      PostgresqlRequirement.new(tags)
    when :python, :python2
      # output_deprecation(spec, tags)
      PythonRequirement.new(tags)
    when :python3
      # output_deprecation(spec, tags)
      Python3Requirement.new(tags)
    when :rbenv
      # output_deprecation(spec, tags)
      RbenvRequirement.new(tags)
    when :ruby
      # output_deprecation(spec, tags)
      RubyRequirement.new(tags)
    else
      _parse_symbol_spec(spec, tags)
    end
  end

  def autotools_dep(spec, tags)
    tags << :build unless tags.include? :run
    Dependency.new(spec.to_s, tags)
  end

  def output_deprecation(dependency, tags, new_dependency = dependency)
    tags_string = if tags.length > 1
      " => [:#{tags.join ", :"}]"
    elsif tags.length == 1
      " => :#{tags.first}"
    end
    odeprecated "'depends_on :#{dependency}'",
                "'depends_on \"#{new_dependency}\"#{tags_string}'"
  end
end
