require "update_migrator/cache_entries_to_double_dashes"
require "update_migrator/cache_entries_to_symlinks"
require "update_migrator/legacy_cache"
require "update_migrator/legacy_keg_symlinks"
require "update_migrator/legacy_repository"

module UpdateMigrator
  module_function

  def formula_resources(formula)
    specs = [formula.stable, formula.devel, formula.head].compact

    [*formula.bottle&.resource] + specs.flat_map do |spec|
      [
        spec,
        *spec.resources.values,
        *spec.patches.select(&:external?).map(&:resource),
      ]
    end
  end

  def parse_extname(url)
    uri_path = if URI::DEFAULT_PARSER.make_regexp =~ url
      uri = URI(url)
      uri.query ? "#{uri.path}?#{uri.query}" : uri.path
    else
      url
    end

    # Given a URL like https://example.com/download.php?file=foo-1.0.tar.gz
    # the extension we want is ".tar.gz", not ".php".
    Pathname.new(uri_path).ascend do |path|
      ext = path.extname[/[^?&]+/]
      return ext if ext
    end

    nil
  end
end
