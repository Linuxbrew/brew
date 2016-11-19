require "dependency_collector"

class DependencyCollector
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
      # TODO: reenable in future when we've fixed a few of the audits.
      # output_deprecation(spec, tags, "apr-util")
      Dependency.new("apr-util", tags)
    when :libltdl
      tags << :run
      output_deprecation("libtool", tags)
      Dependency.new("libtool", tags)
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
