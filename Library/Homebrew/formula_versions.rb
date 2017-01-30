require "formula"

class FormulaVersions
  IGNORED_EXCEPTIONS = [
    ArgumentError, NameError, SyntaxError, TypeError,
    FormulaSpecificationError, FormulaValidationError,
    ErrorDuringExecution, LoadError, MethodDeprecatedError
  ].freeze

  attr_reader :name, :path, :repository, :entry_name

  def initialize(formula, options = {})
    @name = formula.name
    @path = formula.path
    @repository = formula.tap.path
    @entry_name = @path.relative_path_from(repository).to_s
    @max_depth = options[:max_depth]
    @current_formula = formula
  end

  def rev_list(branch)
    repository.cd do
      depth = 0
      Utils.popen_read("git", "rev-list", "--abbrev-commit", "--remove-empty", branch, "--", entry_name) do |io|
        yield io.readline.chomp until io.eof? || (@max_depth && (depth += 1) > @max_depth)
      end
    end
  end

  def file_contents_at_revision(rev)
    repository.cd { Utils.popen_read("git", "cat-file", "blob", "#{rev}:#{entry_name}") }
  end

  def formula_at_revision(rev)
    contents = file_contents_at_revision(rev)

    begin
      Homebrew.raise_deprecation_exceptions = true
      nostdout { yield Formulary.from_contents(name, path, contents) }
    rescue *IGNORED_EXCEPTIONS => e
      # We rescue these so that we can skip bad versions and
      # continue walking the history
      ohai "#{e} in #{name} at revision #{rev}", e.backtrace if ARGV.debug?
    rescue FormulaUnavailableError
      # Suppress this error
    ensure
      Homebrew.raise_deprecation_exceptions = false
    end
  end

  def bottle_version_map(branch)
    map = Hash.new { |h, k| h[k] = [] }
    rev_list(branch) do |rev|
      formula_at_revision(rev) do |f|
        bottle = f.bottle_specification
        map[f.pkg_version] << bottle.rebuild unless bottle.checksums.empty?
      end
    end
    map
  end

  def version_attributes_map(attributes, branch)
    attributes_map = {}
    return attributes_map if attributes.empty?

    attributes.each do |attribute|
      attributes_map[attribute] ||= {}
      # Set the attributes for the current formula in case it's not been
      # committed yet.
      set_attribute_map(attributes_map[attribute], @current_formula, attribute)
    end

    rev_list(branch) do |rev|
      formula_at_revision(rev) do |f|
        attributes.each do |attribute|
          set_attribute_map(attributes_map[attribute], f, attribute)
        end
      end
    end

    attributes_map
  end

  private

  def set_attribute_map(map, f, attribute)
    if f.stable
      map[:stable] ||= {}
      map[:stable][f.stable.version] ||= []
      map[:stable][f.stable.version] << f.send(attribute)
    end
    return unless f.devel
    map[:devel] ||= {}
    map[:devel][f.devel.version] ||= []
    map[:devel][f.devel.version] << f.send(attribute)
  end
end
