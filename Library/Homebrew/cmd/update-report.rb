#: @hide_from_man_page
#:  * `update_report`:
#:    The Ruby implementation of `brew update`. Never called manually.

require "formula_versions"
require "migrator"
require "formulary"
require "descriptions"
require "cleanup"
require "utils"

module Homebrew
  module_function

  def update_preinstall_header
    @header_already_printed ||= begin
      ohai "Auto-updated Homebrew!" if ARGV.include?("--preinstall")
      true
    end
  end

  def update_report
    HOMEBREW_REPOSITORY.cd do
      analytics_message_displayed = \
        Utils.popen_read("git", "config", "--local", "--get", "homebrew.analyticsmessage").chuzzle
      analytics_disabled = \
        Utils.popen_read("git", "config", "--local", "--get", "homebrew.analyticsdisabled").chuzzle
      if analytics_message_displayed != "true" && analytics_disabled != "true" &&
         !ENV["HOMEBREW_NO_ANALYTICS"] && !ENV["HOMEBREW_NO_ANALYTICS_MESSAGE_OUTPUT"]
        ENV["HOMEBREW_NO_ANALYTICS_THIS_RUN"] = "1"
        # Use the shell's audible bell.
        print "\a"

        # Use an extra newline and bold to avoid this being missed.
        ohai "Homebrew has enabled anonymous aggregate user behaviour analytics."
        puts <<-EOS.undent
          #{Tty.bold}Read the analytics documentation (and how to opt-out) here:
            #{Formatter.url("https://docs.brew.sh/Analytics.html")}#{Tty.reset}

        EOS

        # Consider the message possibly missed if not a TTY.
        if $stdout.tty?
          safe_system "git", "config", "--local", "--replace-all", "homebrew.analyticsmessage", "true"
        end
      end
    end

    install_core_tap_if_necessary

    hub = ReporterHub.new
    updated = false

    initial_revision = ENV["HOMEBREW_UPDATE_BEFORE"].to_s
    current_revision = ENV["HOMEBREW_UPDATE_AFTER"].to_s
    if initial_revision.empty? || current_revision.empty?
      odie "update-report should not be called directly!"
    end

    if initial_revision != current_revision
      update_preinstall_header
      puts "Updated Homebrew from #{shorten_revision(initial_revision)} to #{shorten_revision(current_revision)}."
      updated = true
    end

    updated_taps = []
    Tap.each do |tap|
      next unless tap.git?
      begin
        reporter = Reporter.new(tap)
      rescue Reporter::ReporterRevisionUnsetError => e
        onoe "#{e.message}\n#{e.backtrace.join "\n"}" if ARGV.homebrew_developer?
        next
      end
      if reporter.updated?
        updated_taps << tap.name
        hub.add(reporter)
      end
    end

    unless updated_taps.empty?
      update_preinstall_header
      puts "Updated #{Formatter.pluralize(updated_taps.size, "tap")} " \
           "(#{updated_taps.join(", ")})."
      updated = true
    end

    migrate_legacy_cache_if_necessary
    migrate_legacy_keg_symlinks_if_necessary

    if !updated
      if !ARGV.include?("--preinstall") && !ENV["HOMEBREW_UPDATE_FAILED"]
        puts "Already up-to-date."
      end
    else
      if hub.empty?
        puts "No changes to formulae."
      else
        hub.dump
        hub.reporters.each(&:migrate_tap_migration)
        hub.reporters.each(&:migrate_formula_rename)
        Descriptions.update_cache(hub)
      end
      puts if ARGV.include?("--preinstall")
    end

    link_completions_manpages_and_docs
    Tap.each(&:link_completions_and_manpages)

    Homebrew.failed = true if ENV["HOMEBREW_UPDATE_FAILED"]

    # This should always be the last thing to run (but skip on auto-update).
    if !ARGV.include?("--preinstall") ||
       ENV["HOMEBREW_ENABLE_AUTO_UPDATE_MIGRATION"]
      migrate_legacy_repository_if_necessary
    end
  end

  def shorten_revision(revision)
    Utils.popen_read("git", "-C", HOMEBREW_REPOSITORY, "rev-parse", "--short", revision).chomp
  end

  def install_core_tap_if_necessary
    return if ENV["HOMEBREW_UPDATE_TEST"]
    core_tap = CoreTap.instance
    return if core_tap.installed?
    CoreTap.ensure_installed! quiet: false
    revision = core_tap.git_head
    ENV["HOMEBREW_UPDATE_BEFORE_HOMEBREW_HOMEBREW_CORE"] = revision
    ENV["HOMEBREW_UPDATE_AFTER_HOMEBREW_HOMEBREW_CORE"] = revision
  end

  def migrate_legacy_cache_if_necessary
    legacy_cache = Pathname.new "/Library/Caches/Homebrew"
    return if HOMEBREW_CACHE.to_s == legacy_cache.to_s
    return unless legacy_cache.directory?
    return unless legacy_cache.readable_real?

    migration_attempted_file = legacy_cache/".migration_attempted"
    return if migration_attempted_file.exist?

    return unless legacy_cache.writable_real?
    FileUtils.touch migration_attempted_file

    # Cleanup to avoid copying files unnecessarily
    ohai "Cleaning up #{legacy_cache}..."
    Cleanup.cleanup_cache legacy_cache

    # This directory could have been compromised if it's world-writable/
    # a symlink/owned by another user so don't copy files in those cases.
    world_writable = legacy_cache.stat.mode & 0777 == 0777
    return if world_writable
    return if legacy_cache.symlink?
    return if !legacy_cache.owned? && legacy_cache.lstat.uid.nonzero?

    ohai "Migrating #{legacy_cache} to #{HOMEBREW_CACHE}..."
    HOMEBREW_CACHE.mkpath
    legacy_cache.cd do
      legacy_cache.entries.each do |f|
        next if [".", "..", ".migration_attempted"].include? f.to_s
        begin
          FileUtils.cp_r f, HOMEBREW_CACHE
        rescue
          @migration_failed ||= true
        end
      end
    end

    if @migration_failed
      opoo <<-EOS.undent
        Failed to migrate #{legacy_cache} to
        #{HOMEBREW_CACHE}. Please do so manually.
      EOS
    else
      ohai "Deleting #{legacy_cache}..."
      FileUtils.rm_rf legacy_cache
      if legacy_cache.exist?
        FileUtils.touch migration_attempted_file
        opoo <<-EOS.undent
          Failed to delete #{legacy_cache}.
          Please do so manually.
        EOS
      end
    end
  end

  def migrate_legacy_repository_if_necessary
    return unless HOMEBREW_PREFIX.to_s == "/usr/local"
    return unless HOMEBREW_REPOSITORY.to_s == "/usr/local"

    ohai "Migrating HOMEBREW_REPOSITORY (please wait)..."

    unless HOMEBREW_PREFIX.writable_real?
      ofail <<-EOS.undent
        #{HOMEBREW_PREFIX} is not writable.

        You should change the ownership and permissions of #{HOMEBREW_PREFIX}
        temporarily back to your user account so we can complete the Homebrew
        repository migration:
          sudo chown -R $(whoami) #{HOMEBREW_PREFIX}
      EOS
      return
    end

    new_homebrew_repository = Pathname.new "/usr/local/Homebrew"
    new_homebrew_repository.rmdir_if_possible
    if new_homebrew_repository.exist?
      ofail <<-EOS.undent
        #{new_homebrew_repository} already exists.
        Please remove it manually or uninstall and reinstall Homebrew into a new
        location as the migration cannot be done automatically.
      EOS
      return
    end
    new_homebrew_repository.mkpath

    repo_files = HOMEBREW_REPOSITORY.cd do
      Utils.popen_read("git ls-files").lines.map(&:chomp)
    end

    unless Utils.popen_read("git status --untracked-files=all --porcelain").empty?
      HOMEBREW_REPOSITORY.cd do
        quiet_system "git", "merge", "--abort"
        quiet_system "git", "rebase", "--abort"
        quiet_system "git", "reset", "--mixed"
        safe_system "git", "-c", "user.email=brew-update@localhost",
                           "-c", "user.name=brew update",
                           "stash", "save", "--include-untracked"
      end
      stashed = true
    end

    FileUtils.cp_r "#{HOMEBREW_REPOSITORY}/.git", "#{new_homebrew_repository}/.git"
    new_homebrew_repository.cd do
      safe_system "git", "checkout", "--force", "."
      safe_system "git", "stash", "pop" if stashed
    end

    if (HOMEBREW_REPOSITORY/"Library/Locks").exist?
      FileUtils.cp_r "#{HOMEBREW_REPOSITORY}/Library/Locks", "#{new_homebrew_repository}/Library/Locks"
    end

    if (HOMEBREW_REPOSITORY/"Library/Taps").exist?
      FileUtils.cp_r "#{HOMEBREW_REPOSITORY}/Library/Taps", "#{new_homebrew_repository}/Library/Taps"
    end

    unremovable_paths = []
    extra_remove_paths = [".git", "Library/Locks", "Library/Taps",
                          "Library/Homebrew/cask", "Library/Homebrew/test"]
    (repo_files + extra_remove_paths).each do |file|
      path = Pathname.new "#{HOMEBREW_REPOSITORY}/#{file}"
      begin
        FileUtils.rm_rf path
      rescue Errno::EACCES
        unremovable_paths << path
      end
      quiet_system "rmdir", "-p", path.parent if path.parent.exist?
    end

    unless unremovable_paths.empty?
      ofail <<-EOS.undent
        Could not remove old HOMEBREW_REPOSITORY paths!
        Please do this manually with:
          sudo rm -rf #{unremovable_paths.join " "}
      EOS
    end

    (Keg::ALL_TOP_LEVEL_DIRECTORIES + ["Cellar"]).each do |dir|
      FileUtils.mkdir_p "#{HOMEBREW_PREFIX}/#{dir}"
    end

    src = Pathname.new("#{new_homebrew_repository}/bin/brew")
    dst = Pathname.new("#{HOMEBREW_PREFIX}/bin/brew")
    begin
      FileUtils.ln_s(src.relative_path_from(dst.parent), dst)
    rescue Errno::EACCES, Errno::ENOENT
      ofail <<-EOS.undent
        Could not create symlink at #{dst}!
        Please do this manually with:
          sudo ln -sf #{src} #{dst}
          sudo chown $(whoami) #{dst}
      EOS
    end

    link_completions_manpages_and_docs(new_homebrew_repository)

    ohai "Migrated HOMEBREW_REPOSITORY to #{new_homebrew_repository}!"
    puts <<-EOS.undent
      Homebrew no longer needs to have ownership of /usr/local. If you wish you can
      return /usr/local to its default ownership with:
        sudo chown root:wheel #{HOMEBREW_PREFIX}
    EOS
  rescue => e
    ofail <<-EOS.undent
      #{Tty.bold}Failed to migrate HOMEBREW_REPOSITORY to #{new_homebrew_repository}!#{Tty.reset}
      The error was:
        #{e}
      Please try to resolve this error yourself and then run `brew update` again to
      complete the migration. If you need help please +1 an existing error or comment
      with your new error in issue:
        #{Formatter.url("https://github.com/Homebrew/brew/issues/987")}
    EOS
    $stderr.puts e.backtrace
  end

  def link_completions_manpages_and_docs(repository = HOMEBREW_REPOSITORY)
    command = "brew update"
    Utils::Link.link_completions(repository, command)
    Utils::Link.link_manpages(repository, command)
    Utils::Link.link_docs(repository, command)
  rescue => e
    ofail <<-EOS.undent
      Failed to link all completions, docs and manpages:
        #{e}
    EOS
  end
end

class Reporter
  class ReporterRevisionUnsetError < RuntimeError
    def initialize(var_name)
      super "#{var_name} is unset!"
    end
  end

  attr_reader :tap, :initial_revision, :current_revision

  def initialize(tap)
    @tap = tap

    initial_revision_var = "HOMEBREW_UPDATE_BEFORE#{repo_var}"
    @initial_revision = ENV[initial_revision_var].to_s
    raise ReporterRevisionUnsetError, initial_revision_var if @initial_revision.empty?

    current_revision_var = "HOMEBREW_UPDATE_AFTER#{repo_var}"
    @current_revision = ENV[current_revision_var].to_s
    raise ReporterRevisionUnsetError, current_revision_var if @current_revision.empty?
  end

  def report
    return @report if @report

    @report = Hash.new { |h, k| h[k] = [] }
    return @report unless updated?

    diff.each_line do |line|
      status, *paths = line.split
      src = Pathname.new paths.first
      dst = Pathname.new paths.last

      next unless dst.extname == ".rb"

      if paths.any? { |p| tap.cask_file?(p) }
        # Currently only need to handle Cask deletion/migration.
        if status == "D"
          # Have a dedicated report array for deleted casks.
          @report[:DC] << tap.formula_file_to_name(src)
        end
      end

      next unless paths.any? { |p| tap.formula_file?(p) }

      case status
      when "A", "D"
        full_name = tap.formula_file_to_name(src)
        name = full_name.split("/").last
        new_tap = tap.tap_migrations[name]
        @report[status.to_sym] << full_name unless new_tap
      when "M"
        begin
          formula = Formulary.factory(tap.path/src)
          new_version = formula.pkg_version
          old_version = FormulaVersions.new(formula).formula_at_revision(@initial_revision, &:pkg_version)
          next if new_version == old_version
        rescue Exception => e
          onoe "#{e.message}\n#{e.backtrace.join "\n"}" if ARGV.homebrew_developer?
        end
        @report[:M] << tap.formula_file_to_name(src)
      when /^R\d{0,3}/
        src_full_name = tap.formula_file_to_name(src)
        dst_full_name = tap.formula_file_to_name(dst)
        # Don't report formulae that are moved within a tap but not renamed
        next if src_full_name == dst_full_name
        @report[:D] << src_full_name
        @report[:A] << dst_full_name
      end
    end

    renamed_formulae = Set.new
    @report[:D].each do |old_full_name|
      old_name = old_full_name.split("/").last
      new_name = tap.formula_renames[old_name]
      next unless new_name

      if tap.core_tap?
        new_full_name = new_name
      else
        new_full_name = "#{tap}/#{new_name}"
      end

      renamed_formulae << [old_full_name, new_full_name] if @report[:A].include? new_full_name
    end

    @report[:A].each do |new_full_name|
      new_name = new_full_name.split("/").last
      old_name = tap.formula_renames.key(new_name)
      next unless old_name

      if tap.core_tap?
        old_full_name = old_name
      else
        old_full_name = "#{tap}/#{old_name}"
      end

      renamed_formulae << [old_full_name, new_full_name]
    end

    unless renamed_formulae.empty?
      @report[:A] -= renamed_formulae.map(&:last)
      @report[:D] -= renamed_formulae.map(&:first)
      @report[:R] = renamed_formulae.to_a
    end

    @report
  end

  def updated?
    initial_revision != current_revision
  end

  def migrate_tap_migration
    (report[:D] + report[:DC]).each do |full_name|
      name = full_name.split("/").last
      new_tap_name = tap.tap_migrations[name]
      next if new_tap_name.nil? # skip if not in tap_migrations list.

      new_tap_user, new_tap_repo, new_tap_new_name = new_tap_name.split("/")
      new_name = if new_tap_new_name
        new_full_name = new_tap_new_name
        new_tap_name = "#{new_tap_user}/#{new_tap_repo}"
        new_tap_new_name
      else
        new_full_name = "#{new_tap_name}/#{name}"
        name
      end

      # This means it is a Cask
      if report[:DC].include? full_name
        next unless (HOMEBREW_PREFIX/"Caskroom"/new_name).exist?
        new_tap = Tap.fetch(new_tap_name)
        new_tap.install unless new_tap.installed?
        ohai "#{name} has been moved to Homebrew.", <<-EOS.undent
          To uninstall the cask run:
            brew cask uninstall --force #{name}
        EOS
        next if (HOMEBREW_CELLAR/new_name.split("/").last).directory?
        ohai "Installing #{new_name}..."
        system HOMEBREW_BREW_FILE, "install", new_full_name
        begin
          unless Formulary.factory(new_full_name).keg_only?
            system HOMEBREW_BREW_FILE, "link", new_full_name, "--overwrite"
          end
        rescue Exception => e
          onoe "#{e.message}\n#{e.backtrace.join "\n"}" if ARGV.homebrew_developer?
        end
        next
      end

      next unless (dir = HOMEBREW_CELLAR/name).exist? # skip if formula is not installed.
      tabs = dir.subdirs.map { |d| Tab.for_keg(Keg.new(d)) }
      next unless tabs.first.tap == tap # skip if installed formula is not from this tap.
      new_tap = Tap.fetch(new_tap_name)
      # For formulae migrated to cask: Auto-install cask or provide install instructions.
      if new_tap_name == "caskroom/cask"
        if new_tap.installed? && (HOMEBREW_PREFIX/"Caskroom").directory?
          ohai "#{name} has been moved to Homebrew-Cask."
          ohai "brew unlink #{name}"
          system HOMEBREW_BREW_FILE, "unlink", name
          ohai "brew prune"
          system HOMEBREW_BREW_FILE, "prune"
          ohai "brew cask install #{new_name}"
          system HOMEBREW_BREW_FILE, "cask", "install", new_name
          ohai <<-EOS.undent
            #{name} has been moved to Homebrew-Cask.
            The existing keg has been unlinked.
            Please uninstall the formula when convenient by running:
              brew uninstall --force #{name}
          EOS
        else
          ohai "#{name} has been moved to Homebrew-Cask.", <<-EOS.undent
            To uninstall the formula and install the cask run:
              brew uninstall --force #{name}
              brew cask install #{new_name}
          EOS
        end
      else
        new_tap.install unless new_tap.installed?
        # update tap for each Tab
        tabs.each { |tab| tab.tap = new_tap }
        tabs.each(&:write)
      end
    end
  end

  def migrate_formula_rename
    Formula.installed.each do |formula|
      next unless Migrator.needs_migration?(formula)

      oldname = formula.oldname
      oldname_rack = HOMEBREW_CELLAR/oldname

      if oldname_rack.subdirs.empty?
        oldname_rack.rmdir_if_possible
        next
      end

      new_name = tap.formula_renames[oldname]
      next unless new_name

      new_full_name = "#{tap}/#{new_name}"

      begin
        f = Formulary.factory(new_full_name)
      rescue Exception => e
        onoe "#{e.message}\n#{e.backtrace.join "\n"}" if ARGV.homebrew_developer?
        next
      end

      Migrator.migrate_if_needed(f)
    end
  end

  private

  def repo_var
    @repo_var ||= tap.path.to_s
                     .strip_prefix(Tap::TAP_DIRECTORY.to_s)
                     .tr("^A-Za-z0-9", "_")
                     .upcase
  end

  def diff
    Utils.popen_read(
      "git", "-C", tap.path, "diff-tree", "-r", "--name-status", "--diff-filter=AMDR",
      "-M85%", initial_revision, current_revision
    )
  end
end

class ReporterHub
  extend Forwardable

  attr_reader :reporters

  def initialize
    @hash = {}
    @reporters = []
  end

  def select_formula(key)
    @hash.fetch(key, [])
  end

  def add(reporter)
    @reporters << reporter
    report = reporter.report.delete_if { |_k, v| v.empty? }
    @hash.update(report) { |_key, oldval, newval| oldval.concat(newval) }
  end

  delegate :empty? => :@hash

  def dump
    # Key Legend: Added (A), Copied (C), Deleted (D), Modified (M), Renamed (R)

    dump_formula_report :A, "New Formulae"
    dump_formula_report :M, "Updated Formulae"
    dump_formula_report :R, "Renamed Formulae"
    dump_formula_report :D, "Deleted Formulae"
  end

  private

  def dump_formula_report(key, title)
    formulae = select_formula(key).sort.map do |name, new_name|
      # Format list items of renamed formulae
      case key
      when :R
        name = pretty_installed(name) if installed?(name)
        new_name = pretty_installed(new_name) if installed?(new_name)
        "#{name} -> #{new_name}"
      when :A
        name unless installed?(name)
      else
        installed?(name) ? pretty_installed(name) : name
      end
    end.compact

    return if formulae.empty?
    # Dump formula list.
    ohai title
    puts Formatter.columns(formulae)
  end

  def installed?(formula)
    (HOMEBREW_CELLAR/formula.split("/").last).directory?
  end
end
