require "formula"

class FormulaVersions
  IGNORED_EXCEPTIONS = [
    ArgumentError, NameError, SyntaxError, TypeError,
    FormulaSpecificationError, FormulaValidationError,
    ErrorDuringExecution, LoadError, MethodDeprecatedError
  ].freeze

  MAX_VERSIONS_DEPTH = 2

  attr_reader :name, :path, :repository, :entry_name

  def initialize(formula)
    @name = formula.name
    @path = formula.path
    @repository = formula.tap.path
    @entry_name = @path.relative_path_from(repository).to_s
    @current_formula = formula
    @formula_at_revision = {}
  end

  def rev_list(branch)
    repository.cd do
      Utils.popen_read("git", "rev-list", "--abbrev-commit", "--remove-empty", branch, "--", entry_name) do |io|
        yield io.readline.chomp until io.eof?
      end
    end
  end

  def file_contents_at_revision(rev)
    repository.cd { Utils.popen_read("git", "cat-file", "blob", "#{rev}:#{entry_name}") }
  end

  def formula_at_revision(rev)
    Homebrew.raise_deprecation_exceptions = true

    yield @formula_at_revision[rev] ||= begin
      contents = file_contents_at_revision(rev)
      nostdout { Formulary.from_contents(name, path, contents) }
    end
  rescue *IGNORED_EXCEPTIONS => e
    # We rescue these so that we can skip bad versions and
    # continue walking the history
    ohai "#{e} in #{name} at revision #{rev}", e.backtrace if ARGV.debug?
  rescue FormulaUnavailableError
    nil
  ensure
    Homebrew.raise_deprecation_exceptions = false
  end

  def bottle_version_map(branch)
    map = Hash.new { |h, k| h[k] = [] }

    versions_seen = 0
    rev_list(branch) do |rev|
      formula_at_revision(rev) do |f|
        bottle = f.bottle_specification
        map[f.pkg_version] << bottle.rebuild unless bottle.checksums.empty?
        versions_seen = (map.keys + [f.pkg_version]).uniq.length
      end
      return map if versions_seen > MAX_VERSIONS_DEPTH
    end
    map
  end

  def previous_version_and_checksum(branch)
    map = {}

    rev_list(branch) do |rev|
      formula_at_revision(rev) do |f|
        [:stable, :devel].each do |spec_sym|
          next unless spec = f.send(spec_sym)

          map[spec_sym] ||= { version: spec.version, checksum: spec.checksum }
        end
      end

      break if map[:stable] || map[:devel]
    end

    map[:stable] ||= {}
    map[:devel] ||= {}

    map
  end

  def version_attributes_map(attributes, branch)
    attributes_map = {}
    return attributes_map if attributes.empty?

    attributes.each do |attribute|
      attributes_map[attribute] ||= {
        stable: {},
        devel:  {},
      }
    end

    stable_versions_seen = 0
    rev_list(branch) do |rev|
      formula_at_revision(rev) do |f|
        attributes.each do |attribute|
          map = attributes_map[attribute]
          set_attribute_map(map, f, attribute)

          stable_keys_length = (map[:stable].keys + [f.version]).uniq.length
          stable_versions_seen = [stable_versions_seen, stable_keys_length].max
        end
      end
      break if stable_versions_seen > MAX_VERSIONS_DEPTH
    end

    attributes_map
  end

  private

  def set_attribute_map(map, f, attribute)
    if f.stable
      map[:stable][f.stable.version] ||= []
      map[:stable][f.stable.version] << f.send(attribute)
    end
    return unless f.devel

    map[:devel][f.devel.version] ||= []
    map[:devel][f.devel.version] << f.send(attribute)
  end
end
