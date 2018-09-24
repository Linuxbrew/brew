require "rubygems"

require "formula_installer"
require "unpack_strategy"

require "cask/cask_dependencies"
require "cask/download"
require "cask/staged"
require "cask/verify"
require "cask/quarantine"

require "cgi"

module Cask
  class Installer
    extend Predicable
    # TODO: it is unwise for Cask::Staged to be a module, when we are
    #       dealing with both staged and unstaged Casks here. This should
    #       either be a class which is only sometimes instantiated, or there
    #       should be explicit checks on whether staged state is valid in
    #       every method.
    include Staged
    include Verify

    def initialize(cask, command: SystemCommand, force: false,
                   skip_cask_deps: false, binaries: true, verbose: false,
                   require_sha: false, upgrade: false,
                   installed_as_dependency: false, quarantine: true)
      @cask = cask
      @command = command
      @force = force
      @skip_cask_deps = skip_cask_deps
      @binaries = binaries
      @verbose = verbose
      @require_sha = require_sha
      @reinstall = false
      @upgrade = upgrade
      @installed_as_dependency = installed_as_dependency
      @quarantine = quarantine
    end

    attr_predicate :binaries?, :force?, :skip_cask_deps?, :require_sha?,
                   :upgrade?, :verbose?, :installed_as_dependency?,
                   :quarantine?

    def self.print_caveats(cask)
      odebug "Printing caveats"

      caveats = cask.caveats
      return if caveats.empty?

      ohai "Caveats"
      puts caveats + "\n"
    end

    def fetch
      odebug "Cask::Installer#fetch"

      satisfy_dependencies

      verify_has_sha if require_sha? && !force?
      download
      verify
    end

    def stage
      odebug "Cask::Installer#stage"

      Caskroom.ensure_caskroom_exists

      unpack_dependencies

      extract_primary_container
      save_caskfile
    rescue => e
      purge_versioned_files
      raise e
    end

    def install
      odebug "Cask::Installer#install"

      if @cask.installed? && !force? && !@reinstall && !upgrade?
        raise CaskAlreadyInstalledError, @cask
      end

      check_conflicts

      print_caveats
      fetch
      uninstall_existing_cask if @reinstall

      oh1 "Installing Cask #{Formatter.identifier(@cask)}"
      opoo "macOS's Gatekeeper has been disabled for this Cask" unless quarantine?
      stage
      install_artifacts
      enable_accessibility_access

      unless @cask.tap&.private?
        ::Utils::Analytics.report_event("cask_install", @cask.token)
      end

      puts summary
    end

    def check_conflicts
      return unless @cask.conflicts_with

      @cask.conflicts_with.cask.each do |conflicting_cask|
        begin
          conflicting_cask = CaskLoader.load(conflicting_cask)
          if conflicting_cask.installed?
            raise CaskConflictError.new(@cask, conflicting_cask)
          end
        rescue CaskUnavailableError
          next # Ignore conflicting Casks that do not exist.
        end
      end
    end

    def reinstall
      odebug "Cask::Installer#reinstall"
      @reinstall = true
      install
    end

    def uninstall_existing_cask
      return unless @cask.installed?

      # use the same cask file that was used for installation, if possible
      installed_caskfile = @cask.installed_caskfile
      installed_cask = installed_caskfile.exist? ? CaskLoader.load(installed_caskfile) : @cask

      # Always force uninstallation, ignore method parameter
      Installer.new(installed_cask, binaries: binaries?, verbose: verbose?, force: true, upgrade: upgrade?).uninstall
    end

    def summary
      s = ""
      s << "#{Emoji.install_badge}  " if Emoji.enabled?
      s << "#{@cask} was successfully #{upgrade? ? "upgraded" : "installed"}!"
    end

    def download
      odebug "Downloading"
      @downloaded_path = Download.new(@cask, force: false, quarantine: quarantine?).perform
      odebug "Downloaded to -> #{@downloaded_path}"
      @downloaded_path
    end

    def verify_has_sha
      odebug "Checking cask has checksum"
      return unless @cask.sha256 == :no_check

      raise CaskNoShasumError, @cask.token
    end

    def verify
      Verify.all(@cask, @downloaded_path)
    end

    def primary_container
      @primary_container ||= begin
        UnpackStrategy.detect(@downloaded_path, type: @cask.container&.type)
      end
    end

    def extract_primary_container
      odebug "Extracting primary container"

      odebug "Using container class #{primary_container.class} for #{@downloaded_path}"

      basename = CGI.unescape(File.basename(@cask.url.path))

      if nested_container = @cask.container&.nested
        Dir.mktmpdir do |tmpdir|
          tmpdir = Pathname(tmpdir)
          primary_container.extract(to: tmpdir, basename: basename, verbose: verbose?)

          UnpackStrategy.detect(tmpdir/nested_container)
                        .extract_nestedly(to: @cask.staged_path, verbose: verbose?)
        end
      else
        primary_container.extract_nestedly(to: @cask.staged_path, basename: basename, verbose: verbose?)
      end

      return unless quarantine?
      return unless Quarantine.available?

      Quarantine.propagate(from: @downloaded_path, to: @cask.staged_path)
    end

    def install_artifacts
      already_installed_artifacts = []

      odebug "Installing artifacts"
      artifacts = @cask.artifacts
      odebug "#{artifacts.length} artifact/s defined", artifacts

      artifacts.each do |artifact|
        next unless artifact.respond_to?(:install_phase)

        odebug "Installing artifact of class #{artifact.class}"

        if artifact.is_a?(Artifact::Binary)
          next unless binaries?
        end

        artifact.install_phase(command: @command, verbose: verbose?, force: force?)
        already_installed_artifacts.unshift(artifact)
      end
    rescue => e
      begin
        already_installed_artifacts.each do |artifact|
          next unless artifact.respond_to?(:uninstall_phase)

          odebug "Reverting installation of artifact of class #{artifact.class}"
          artifact.uninstall_phase(command: @command, verbose: verbose?, force: force?)
        end
      ensure
        purge_versioned_files
        raise e
      end
    end

    # TODO: move dependencies to a separate class
    #       dependencies should also apply for "brew cask stage"
    #       override dependencies with --force or perhaps --force-deps
    def satisfy_dependencies
      return unless @cask.depends_on

      ohai "Satisfying dependencies"
      macos_dependencies
      arch_dependencies
      x11_dependencies
      formula_dependencies
      cask_dependencies unless skip_cask_deps? || installed_as_dependency?
    end

    def macos_dependencies
      return unless @cask.depends_on.macos

      if @cask.depends_on.macos.first.is_a?(Array)
        operator, release = @cask.depends_on.macos.first
        unless MacOS.version.send(operator, release)
          raise CaskError,
            "Cask #{@cask} depends on macOS release #{operator} #{release}, " \
            "but you are running release #{MacOS.version}."
        end
      elsif @cask.depends_on.macos.length > 1
        unless @cask.depends_on.macos.include?(Gem::Version.new(MacOS.version.to_s))
          raise CaskError,
            "Cask #{@cask} depends on macOS release being one of " \
            "[#{@cask.depends_on.macos.map(&:to_s).join(", ")}], " \
            "but you are running release #{MacOS.version}."
        end
      else
        unless MacOS.version == @cask.depends_on.macos.first
          raise CaskError,
            "Cask #{@cask} depends on macOS release " \
            "#{@cask.depends_on.macos.first}, " \
            "but you are running release #{MacOS.version}."
        end
      end
    end

    def arch_dependencies
      return if @cask.depends_on.arch.nil?

      @current_arch ||= { type: Hardware::CPU.type, bits: Hardware::CPU.bits }
      return if @cask.depends_on.arch.any? do |arch|
        arch[:type] == @current_arch[:type] &&
        Array(arch[:bits]).include?(@current_arch[:bits])
      end

      raise CaskError,
        "Cask #{@cask} depends on hardware architecture being one of " \
        "[#{@cask.depends_on.arch.map(&:to_s).join(", ")}], " \
        "but you are running #{@current_arch}"
    end

    def x11_dependencies
      return unless @cask.depends_on.x11
      raise CaskX11DependencyError, @cask.token unless MacOS::X11.installed?
    end

    def formula_dependencies
      formulae = @cask.depends_on.formula.map { |f| Formula[f] }
      return if formulae.empty?

      if formulae.all?(&:any_version_installed?)
        puts "All Formula dependencies satisfied."
        return
      end

      not_installed = formulae.reject(&:any_version_installed?)

      ohai "Installing Formula dependencies: #{not_installed.map(&:to_s).join(", ")}"
      not_installed.each do |formula|
        FormulaInstaller.new(formula).tap do |fi|
          fi.installed_as_dependency = true
          fi.installed_on_request = false
          fi.show_header = true
          fi.verbose = verbose?
          fi.prelude
          fi.install
          fi.finish
        end
      end
    end

    def cask_dependencies
      casks = CaskDependencies.new(@cask)
      return if casks.empty?

      if casks.all?(&:installed?)
        puts "All Cask dependencies satisfied."
        return
      end

      not_installed = casks.reject(&:installed?)

      ohai "Installing Cask dependencies: #{not_installed.map(&:to_s).join(", ")}"
      not_installed.each do |cask|
        Installer.new(
          cask,
          binaries: binaries?,
          verbose: verbose?,
          installed_as_dependency: true,
          force: false,
        ).install
      end
    end

    def unpack_dependencies
      formulae = primary_container.dependencies.select { |dep| dep.is_a?(Formula) }
      casks = primary_container.dependencies.select { |dep| dep.is_a?(Cask) }
                               .flat_map { |cask| [*CaskDependencies.new(cask), cask] }

      not_installed_formulae = formulae.reject(&:any_version_installed?)
      not_installed_casks = casks.reject(&:installed?)

      return if (not_installed_formulae + not_installed_casks).empty?

      ohai "Satisfying unpack dependencies"

      not_installed_formulae.each do |formula|
        FormulaInstaller.new(formula).tap do |fi|
          fi.installed_as_dependency = true
          fi.installed_on_request = false
          fi.show_header = true
          fi.verbose = verbose?
          fi.prelude
          fi.install
          fi.finish
        end
      end

      not_installed_casks.each do |cask|
        Installer.new(cask, verbose: verbose?, installed_as_dependency: true).install
      end
    end

    def print_caveats
      self.class.print_caveats(@cask)
    end

    # TODO: logically could be in a separate class
    def enable_accessibility_access
      return unless @cask.accessibility_access

      ohai "Enabling accessibility access"
      if MacOS.version <= :mountain_lion
        @command.run!(
          "/usr/bin/touch",
          args: [MacOS.pre_mavericks_accessibility_dotfile],
          sudo: true,
        )
      elsif MacOS.version <= :yosemite
        @command.run!(
          "/usr/bin/sqlite3",
          args: [
            MacOS.tcc_db,
            "INSERT OR REPLACE INTO access " \
            "VALUES('kTCCServiceAccessibility','#{bundle_identifier}',0,1,1,NULL);",
          ],
          sudo: true,
        )
      elsif MacOS.version <= :el_capitan
        @command.run!(
          "/usr/bin/sqlite3",
          args: [
            MacOS.tcc_db,
            "INSERT OR REPLACE INTO access " \
            "VALUES('kTCCServiceAccessibility','#{bundle_identifier}',0,1,1,NULL,NULL);",
          ],
          sudo: true,
        )
      else
        opoo <<~EOS
          Accessibility access cannot be enabled automatically on this version of macOS.
          See System Preferences to enable it manually.
        EOS
      end
    rescue => e
      purge_versioned_files
      raise e
    end

    def disable_accessibility_access
      return unless @cask.accessibility_access

      if MacOS.version >= :mavericks && MacOS.version <= :el_capitan
        ohai "Disabling accessibility access"
        @command.run!("/usr/bin/sqlite3",
                      args: [
                        MacOS.tcc_db,
                        "DELETE FROM access WHERE client='#{bundle_identifier}';",
                      ],
                      sudo: true)
      else
        opoo <<~EOS
          Accessibility access cannot be disabled automatically on this version of macOS.
          See System Preferences to disable it manually.
        EOS
      end
    end

    def save_caskfile
      old_savedir = @cask.metadata_timestamped_path

      return unless @cask.sourcefile_path

      savedir = @cask.metadata_subdir("Casks", timestamp: :now, create: true)
      FileUtils.copy @cask.sourcefile_path, savedir
      old_savedir&.rmtree
    end

    def uninstall
      oh1 "Uninstalling Cask #{Formatter.identifier(@cask)}"
      disable_accessibility_access
      uninstall_artifacts(clear: true)
      purge_versioned_files
      purge_caskroom_path if force?
    end

    def start_upgrade
      oh1 "Starting upgrade for Cask #{Formatter.identifier(@cask)}"

      disable_accessibility_access
      uninstall_artifacts
      backup
    end

    def backup
      @cask.staged_path.rename backup_path
      @cask.metadata_versioned_path.rename backup_metadata_path
    end

    def restore_backup
      return unless backup_path.directory? && backup_metadata_path.directory?

      Pathname.new(@cask.staged_path).rmtree if @cask.staged_path.exist?
      Pathname.new(@cask.metadata_versioned_path).rmtree if @cask.metadata_versioned_path.exist?

      backup_path.rename @cask.staged_path
      backup_metadata_path.rename @cask.metadata_versioned_path
    end

    def revert_upgrade
      opoo "Reverting upgrade for Cask #{@cask}"
      restore_backup
      install_artifacts
      enable_accessibility_access
    end

    def finalize_upgrade
      purge_backed_up_versioned_files

      puts summary
    end

    def uninstall_artifacts(clear: false)
      odebug "Un-installing artifacts"
      artifacts = @cask.artifacts

      odebug "#{artifacts.length} artifact/s defined", artifacts

      artifacts.each do |artifact|
        next unless artifact.respond_to?(:uninstall_phase)

        odebug "Un-installing artifact of class #{artifact.class}"
        artifact.uninstall_phase(command: @command, verbose: verbose?, skip: clear, force: force?)
      end
    end

    def zap
      ohai %Q(Implied "brew cask uninstall #{@cask}")
      uninstall_artifacts
      if (zap_stanzas = @cask.artifacts.select { |a| a.is_a?(Artifact::Zap) }).empty?
        opoo "No zap stanza present for Cask '#{@cask}'"
      else
        ohai "Dispatching zap stanza"
        zap_stanzas.each do |stanza|
          stanza.zap_phase(command: @command, verbose: verbose?, force: force?)
        end
      end
      ohai "Removing all staged versions of Cask '#{@cask}'"
      purge_caskroom_path
    end

    def backup_path
      return if @cask.staged_path.nil?

      Pathname("#{@cask.staged_path}.upgrading")
    end

    def backup_metadata_path
      return if @cask.metadata_versioned_path.nil?

      Pathname("#{@cask.metadata_versioned_path}.upgrading")
    end

    def gain_permissions_remove(path)
      Utils.gain_permissions_remove(path, command: @command)
    end

    def purge_backed_up_versioned_files
      ohai "Purging files for version #{@cask.version} of Cask #{@cask}"

      # versioned staged distribution
      gain_permissions_remove(backup_path) if backup_path&.exist?

      # Homebrew Cask metadata
      return unless backup_metadata_path.directory?

      backup_metadata_path.children.each do |subdir|
        gain_permissions_remove(subdir)
      end
      backup_metadata_path.rmdir_if_possible
    end

    def purge_versioned_files
      ohai "Purging files for version #{@cask.version} of Cask #{@cask}"

      # versioned staged distribution
      gain_permissions_remove(@cask.staged_path) if @cask.staged_path&.exist?

      # Homebrew Cask metadata
      if @cask.metadata_versioned_path.directory?
        @cask.metadata_versioned_path.children.each do |subdir|
          gain_permissions_remove(subdir)
        end

        @cask.metadata_versioned_path.rmdir_if_possible
      end
      @cask.metadata_master_container_path.rmdir_if_possible unless upgrade?

      # toplevel staged distribution
      @cask.caskroom_path.rmdir_if_possible unless upgrade?
    end

    def purge_caskroom_path
      odebug "Purging all staged versions of Cask #{@cask}"
      gain_permissions_remove(@cask.caskroom_path)
    end
  end
end
