require "dependency_collector"

class DependencyCollector
  alias _parse_string_spec parse_string_spec

  # Define the languages that we can handle as external dependencies.
  LANGUAGE_MODULES = Set[
    :lua, :lua51, :perl, :python, :python3, :ruby
  ].freeze

  def parse_string_spec(spec, tags)
    if (tag = tags.first) && LANGUAGE_MODULES.include?(tag)
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
    when :autoconf, :automake, :bsdmake, :libtool
      output_deprecation(spec, tags)
      autotools_dep(spec, tags)
    when :cairo, :fontconfig, :freetype, :libpng, :pixman
      output_deprecation(spec, tags)
      Dependency.new(spec.to_s, tags)
    when :apr
      # output_deprecation(spec, tags, "apr-util")
      Dependency.new("apr-util", tags)
    when :libltdl
      tags << :run
      output_deprecation("libtool", tags)
      Dependency.new("libtool", tags)
    when :mysql
      # output_deprecation("mysql", tags)
      MysqlRequirement.new(tags)
    when :postgresql
      # output_deprecation("postgresql", tags)
      PostgresqlRequirement.new(tags)
    when :gpg
      # output_deprecation("gnupg", tags)
      GPG2Requirement.new(tags)
    when :rbenv
      # output_deprecation("rbenv", tags)
      RbenvRequirement.new(tags)
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
