require "formulary"
require "tap"

module Homebrew
  module_function

  # name should not be qualified, since migration of qualified names is already
  # handled in Formulary::TapLoader.formula_name_path.
  def search_for_migrated_formula(name, options = {})
    print_messages = options.fetch(:print_messages, true)
    migrations = []
    Tap.each do |old_tap|
      new_tap_name = old_tap.tap_migrations[name]
      next unless new_tap_name
      migrations << [old_tap, new_tap_name]
      next unless print_messages
      deprecation = (new_tap_name == "homebrew/boneyard") ? "deprecated " : ""
      puts "A #{deprecation}formula named \"#{name}\" has been migrated from #{old_tap} to #{new_tap_name}."
    end
    migrations
  end

  # name may be qualified.
  def search_for_deleted_formula(name, options = {})
    print_messages = options.fetch(:print_messages, true)
    warn_shallow = options.fetch(:warn_shallow, false)

    path = Formulary.path name
    raise FormulaExistsError.new(name, path) if File.exist? path
    path.to_s =~ HOMEBREW_TAP_PATH_REGEX
    tap = Tap.new ($1 == "Homebrew" ? "homebrew" : $1), $2.strip_prefix("homebrew-")
    raise TapUnavailableError, tap.name unless File.exist? tap.path
    relpath = path.relative_path_from tap.path

    cd tap.path

    if warn_shallow && File.exist?(".git/shallow")
      opoo <<-EOS.undend
        The git repository is a shallow clone therefore the output may be incomplete.
        Use `git fetch -C #{tap.path} --unshallow` to get the full repository.
      EOS
    end

    log_cmd = "git log --name-only --max-count=1 --format=$'format:%H\\n%h' -- #{relpath}"
    hash, hash_abbrev, relpath = Utils.popen_read(log_cmd).lines.map(&:chomp)
    if hash.to_s.empty? || hash_abbrev.to_s.empty? || relpath.to_s.empty?
      raise FormulaUnavailableError, name
    end

    if print_messages
      puts "#{name} was deleted from #{tap.name} in commit #{hash_abbrev}."
      puts "Run `brew boneyard #{name}` to show the formula's content prior to its removal."
    end

    [tap, relpath, hash, hash_abbrev]
  end
end
