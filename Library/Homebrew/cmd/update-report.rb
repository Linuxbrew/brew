#: @hide_from_man_page
#:  * `update_report` [`--preinstall`]:
#:    The Ruby implementation of `brew update`. Never called manually.

require "formula_versions"
require "migrator"
require "formulary"
require "descriptions"
require "cleanup"
require "update_migrator"

module Homebrew
  module_function

  def update_preinstall_header
    @update_preinstall_header ||= begin
      ohai "Auto-updated Homebrew!" if ARGV.include?("--preinstall")
      true
    end
  end

  def update_report
    HOMEBREW_REPOSITORY.cd do
      analytics_message_displayed =
        Utils.popen_read("git", "config", "--local", "--get", "homebrew.analyticsmessage").chuzzle
      cask_analytics_message_displayed =
        Utils.popen_read("git", "config", "--local", "--get", "homebrew.caskanalyticsmessage").chuzzle
      analytics_disabled =
        Utils.popen_read("git", "config", "--local", "--get", "homebrew.analyticsdisabled").chuzzle
      if analytics_message_displayed != "true" &&
         cask_analytics_message_displayed != "true" &&
         analytics_disabled != "true" &&
         !ENV["HOMEBREW_NO_ANALYTICS"] &&
         !ENV["HOMEBREW_NO_ANALYTICS_MESSAGE_OUTPUT"]

        ENV["HOMEBREW_NO_ANALYTICS_THIS_RUN"] = "1"
        # Use the shell's audible bell.
        print "\a"

        # Use an extra newline and bold to avoid this being missed.
        ohai "Homebrew has enabled anonymous aggregate formulae and cask analytics."
        puts <<~EOS
          #{Tty.bold}Read the analytics documentation (and how to opt-out) here:
            #{Formatter.url("https://docs.brew.sh/Analytics")}#{Tty.reset}

        EOS

        # Consider the message possibly missed if not a TTY.
        if $stdout.tty?
          safe_system "git", "config", "--local", "--replace-all", "homebrew.analyticsmessage", "true"
          safe_system "git", "config", "--local", "--replace-all", "homebrew.caskanalyticsmessage", "true"
        end
      end

      donation_message_displayed =
        Utils.popen_read("git", "config", "--local", "--get", "homebrew.donationmessage").chuzzle
      if donation_message_displayed != "true"
        ohai "Homebrew is run entirely by unpaid volunteers. Please consider donating:"
        puts "  #{Formatter.url("https://github.com/Homebrew/brew#donations")}\n"

        # Consider the message possibly missed if not a TTY.
        if $stdout.tty?
          safe_system "git", "config", "--local", "--replace-all", "homebrew.donationmessage", "true"
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

    out, _, status = system_command("git",
                                    args: ["describe", "--tags", "--abbrev=0", initial_revision],
                                    chdir: HOMEBREW_REPOSITORY,
                                    print_stderr: false)

    initial_version = Version.new(out) if status.success?

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

    UpdateMigrator.migrate_legacy_cache_if_necessary
    UpdateMigrator.migrate_cache_entries_to_double_dashes(initial_version)
    UpdateMigrator.migrate_cache_entries_to_symlinks(initial_version)
    UpdateMigrator.migrate_legacy_keg_symlinks_if_necessary

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
      UpdateMigrator.migrate_legacy_repository_if_necessary
    end
  end

  def shorten_revision(revision)
    Utils.popen_read("git", "-C", HOMEBREW_REPOSITORY, "rev-parse", "--short", revision).chomp
  end

  def install_core_tap_if_necessary
    return if ENV["HOMEBREW_UPDATE_TEST"]

    core_tap = CoreTap.instance
    return if core_tap.installed?

    CoreTap.ensure_installed!
    revision = core_tap.git_head
    ENV["HOMEBREW_UPDATE_BEFORE_HOMEBREW_HOMEBREW_CORE"] = revision
    ENV["HOMEBREW_UPDATE_AFTER_HOMEBREW_HOMEBREW_CORE"] = revision
  end

  def link_completions_manpages_and_docs(repository = HOMEBREW_REPOSITORY)
    command = "brew update"
    Utils::Link.link_completions(repository, command)
    Utils::Link.link_manpages(repository, command)
    Utils::Link.link_docs(repository, command)
  rescue => e
    ofail <<~EOS
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

    initial_revision_var = "HOMEBREW_UPDATE_BEFORE#{tap.repo_var}"
    @initial_revision = ENV[initial_revision_var].to_s
    raise ReporterRevisionUnsetError, initial_revision_var if @initial_revision.empty?

    current_revision_var = "HOMEBREW_UPDATE_AFTER#{tap.repo_var}"
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
        rescue Exception => e # rubocop:disable Lint/RescueException
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
        ohai "#{name} has been moved to Homebrew.", <<~EOS
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
        rescue Exception => e # rubocop:disable Lint/RescueException
          onoe "#{e.message}\n#{e.backtrace.join "\n"}" if ARGV.homebrew_developer?
        end
        next
      end

      next unless (dir = HOMEBREW_CELLAR/name).exist? # skip if formula is not installed.

      tabs = dir.subdirs.map { |d| Tab.for_keg(Keg.new(d)) }
      next unless tabs.first.tap == tap # skip if installed formula is not from this tap.

      new_tap = Tap.fetch(new_tap_name)
      # For formulae migrated to cask: Auto-install cask or provide install instructions.
      if new_tap_name.start_with?("homebrew/cask")
        if new_tap.installed? && (HOMEBREW_PREFIX/"Caskroom").directory?
          ohai "#{name} has been moved to Homebrew Cask."
          ohai "brew unlink #{name}"
          system HOMEBREW_BREW_FILE, "unlink", name
          ohai "brew prune"
          system HOMEBREW_BREW_FILE, "prune"
          ohai "brew cask install #{new_name}"
          system HOMEBREW_BREW_FILE, "cask", "install", new_name
          ohai <<~EOS
            #{name} has been moved to Homebrew Cask.
            The existing keg has been unlinked.
            Please uninstall the formula when convenient by running:
              brew uninstall --force #{name}
          EOS
        else
          ohai "#{name} has been moved to Homebrew Cask.", <<~EOS
            To uninstall the formula and install the cask run:
              brew uninstall --force #{name}
              brew tap #{new_tap_name}
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
      rescue Exception => e # rubocop:disable Lint/RescueException
        onoe "#{e.message}\n#{e.backtrace.join "\n"}" if ARGV.homebrew_developer?
        next
      end

      Migrator.migrate_if_needed(f)
    end
  end

  private

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
    puts Formatter.columns(formulae.sort)
  end

  def installed?(formula)
    (HOMEBREW_CELLAR/formula.split("/").last).directory?
  end
end
