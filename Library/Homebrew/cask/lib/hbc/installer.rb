require "rubygems"

require "formula_installer"

require "hbc/cask_dependencies"
require "hbc/staged"
require "hbc/verify"

module Hbc
  class Installer
    extend Predicable
    # TODO: it is unwise for Hbc::Staged to be a module, when we are
    #       dealing with both staged and unstaged Casks here. This should
    #       either be a class which is only sometimes instantiated, or there
    #       should be explicit checks on whether staged state is valid in
    #       every method.
    include Staged
    include Verify

    PERSISTENT_METADATA_SUBDIRS = ["gpg"].freeze

    def initialize(cask, command: SystemCommand, force: false, skip_cask_deps: false, binaries: true, verbose: false, require_sha: false)
      @cask = cask
      @command = command
      @force = force
      @skip_cask_deps = skip_cask_deps
      @binaries = binaries
      @verbose = verbose
      @require_sha = require_sha
      @reinstall = false
    end

    attr_predicate :binaries?, :force?, :skip_cask_deps?, :require_sha?, :verbose?

    def self.print_caveats(cask)
      odebug "Printing caveats"
      return if cask.caveats.empty?

      output = capture_output do
        cask.caveats.each do |caveat|
          if caveat.respond_to?(:eval_and_print)
            caveat.eval_and_print(cask)
          else
            puts caveat
          end
        end
      end

      return if output.empty?
      ohai "Caveats"
      puts output
    end

    def self.capture_output(&block)
      old_stdout = $stdout
      $stdout = Buffer.new($stdout.tty?)
      block.call
      output = $stdout.string
      $stdout = old_stdout
      output
    end

    def fetch
      odebug "Hbc::Installer#fetch"

      satisfy_dependencies
      verify_has_sha if require_sha? && !force?
      download
      verify
    end

    def stage
      odebug "Hbc::Installer#stage"

      extract_primary_container
      save_caskfile
    rescue StandardError => e
      purge_versioned_files
      raise e
    end

    def install
      odebug "Hbc::Installer#install"

      if @cask.installed? && !force? && !@reinstall
        raise CaskAlreadyInstalledError, @cask
      end

      check_conflicts

      print_caveats
      fetch
      uninstall_existing_cask if @reinstall

      oh1 "Installing Cask #{@cask}"
      stage
      install_artifacts
      enable_accessibility_access

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
      odebug "Hbc::Installer#reinstall"
      @reinstall = true
      install
    end

    def uninstall_existing_cask
      return unless @cask.installed?

      # use the same cask file that was used for installation, if possible
      installed_caskfile = @cask.installed_caskfile
      installed_cask = installed_caskfile.exist? ? CaskLoader.load_from_file(installed_caskfile) : @cask

      # Always force uninstallation, ignore method parameter
      Installer.new(installed_cask, binaries: binaries?, verbose: verbose?, force: true).uninstall
    end

    def summary
      s = ""
      s << "#{Emoji.install_badge}  " if Emoji.enabled?
      s << "#{@cask} was successfully installed!"
    end

    def download
      odebug "Downloading"
      @downloaded_path = Download.new(@cask, force: false).perform
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

    def extract_primary_container
      odebug "Extracting primary container"

      FileUtils.mkdir_p @cask.staged_path
      container = if @cask.container && @cask.container.type
        Container.from_type(@cask.container.type)
      else
        Container.for_path(@downloaded_path, @command)
      end

      unless container
        raise CaskError, "Uh oh, could not figure out how to unpack '#{@downloaded_path}'"
      end

      odebug "Using container class #{container} for #{@downloaded_path}"
      container.new(@cask, @downloaded_path, @command, verbose: verbose?).extract
    end

    def install_artifacts
      already_installed_artifacts = []

      odebug "Installing artifacts"
      artifacts = Artifact.for_cask(@cask, command: @command, verbose: verbose?, force: force?)
      odebug "#{artifacts.length} artifact/s defined", artifacts

      artifacts.each do |artifact|
        next unless artifact.respond_to?(:install_phase)
        odebug "Installing artifact of class #{artifact.class}"

        if artifact.is_a?(Artifact::Binary)
          next unless binaries?
        end

        artifact.install_phase
        already_installed_artifacts.unshift(artifact)
      end
    rescue StandardError => e
      begin
        already_installed_artifacts.each do |artifact|
          next unless artifact.respond_to?(:uninstall_phase)
          odebug "Reverting installation of artifact of class #{artifact.class}"
          artifact.uninstall_phase
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
      cask_dependencies unless skip_cask_deps?
    end

    def macos_dependencies
      return unless @cask.depends_on.macos
      if @cask.depends_on.macos.first.is_a?(Array)
        operator, release = @cask.depends_on.macos.first
        unless MacOS.version.send(operator, release)
          raise CaskError, "Cask #{@cask} depends on macOS release #{operator} #{release}, but you are running release #{MacOS.version}."
        end
      elsif @cask.depends_on.macos.length > 1
        unless @cask.depends_on.macos.include?(Gem::Version.new(MacOS.version.to_s))
          raise CaskError, "Cask #{@cask} depends on macOS release being one of [#{@cask.depends_on.macos.map(&:to_s).join(", ")}], but you are running release #{MacOS.version}."
        end
      else
        unless MacOS.version == @cask.depends_on.macos.first
          raise CaskError, "Cask #{@cask} depends on macOS release #{@cask.depends_on.macos.first}, but you are running release #{MacOS.version}."
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
      raise CaskError, "Cask #{@cask} depends on hardware architecture being one of [#{@cask.depends_on.arch.map(&:to_s).join(", ")}], but you are running #{@current_arch}"
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
        begin
          old_argv = ARGV.dup
          ARGV.replace([])
          FormulaInstaller.new(formula).tap do |fi|
            fi.installed_as_dependency = true
            fi.installed_on_request = false
            fi.show_header = true
            fi.verbose = verbose?
            fi.prelude
            fi.install
            fi.finish
          end
        ensure
          ARGV.replace(old_argv)
        end
      end
    end

    def cask_dependencies
      return if @cask.depends_on.cask.empty?
      casks = CaskDependencies.new(@cask)

      if casks.all?(&:installed?)
        puts "All Cask dependencies satisfied."
        return
      end

      not_installed = casks.reject(&:installed?)

      ohai "Installing Cask dependencies: #{not_installed.map(&:to_s).join(", ")}"
      not_installed.each do |cask|
        Installer.new(cask, binaries: binaries?, verbose: verbose?, skip_cask_deps: true, force: false).install
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
        @command.run!("/usr/bin/touch",
                      args: [Hbc.pre_mavericks_accessibility_dotfile],
                      sudo: true)
      elsif MacOS.version <= :yosemite
        @command.run!("/usr/bin/sqlite3",
                      args: [
                        Hbc.tcc_db,
                        "INSERT OR REPLACE INTO access VALUES('kTCCServiceAccessibility','#{bundle_identifier}',0,1,1,NULL);",
                      ],
                      sudo: true)
      elsif MacOS.version <= :el_capitan
        @command.run!("/usr/bin/sqlite3",
                      args: [
                        Hbc.tcc_db,
                        "INSERT OR REPLACE INTO access VALUES('kTCCServiceAccessibility','#{bundle_identifier}',0,1,1,NULL,NULL);",
                      ],
                      sudo: true)
      else
        opoo <<-EOS.undent
          Accessibility access cannot be enabled automatically on this version of macOS.
          See System Preferences to enable it manually.
        EOS
      end
    rescue StandardError => e
      purge_versioned_files
      raise e
    end

    def disable_accessibility_access
      return unless @cask.accessibility_access
      if MacOS.version >= :mavericks && MacOS.version <= :el_capitan
        ohai "Disabling accessibility access"
        @command.run!("/usr/bin/sqlite3",
                      args: [
                        Hbc.tcc_db,
                        "DELETE FROM access WHERE client='#{bundle_identifier}';",
                      ],
                      sudo: true)
      else
        opoo <<-EOS.undent
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
      old_savedir.rmtree unless old_savedir.nil?
    end

    def uninstall
      oh1 "Uninstalling Cask #{@cask}"
      disable_accessibility_access
      uninstall_artifacts
      purge_versioned_files
      purge_caskroom_path if force?
    end

    def uninstall_artifacts
      odebug "Un-installing artifacts"
      artifacts = Artifact.for_cask(@cask, command: @command, verbose: verbose?, force: force?)

      odebug "#{artifacts.length} artifact/s defined", artifacts

      artifacts.each do |artifact|
        next unless artifact.respond_to?(:uninstall_phase)
        odebug "Un-installing artifact of class #{artifact.class}"
        artifact.uninstall_phase
      end
    end

    def zap
      ohai %Q(Implied "brew cask uninstall #{@cask}")
      uninstall_artifacts
      if Artifact::Zap.me?(@cask)
        ohai "Dispatching zap stanza"
        Artifact::Zap.new(@cask, command: @command).zap_phase
      else
        opoo "No zap stanza present for Cask '#{@cask}'"
      end
      ohai "Removing all staged versions of Cask '#{@cask}'"
      purge_caskroom_path
    end

    def gain_permissions_remove(path)
      Utils.gain_permissions_remove(path, command: @command)
    end

    def purge_versioned_files
      odebug "Purging files for version #{@cask.version} of Cask #{@cask}"

      # versioned staged distribution
      gain_permissions_remove(@cask.staged_path) if !@cask.staged_path.nil? && @cask.staged_path.exist?

      # Homebrew-Cask metadata
      if @cask.metadata_versioned_path.respond_to?(:children) &&
         @cask.metadata_versioned_path.exist?
        @cask.metadata_versioned_path.children.each do |subdir|
          unless PERSISTENT_METADATA_SUBDIRS.include?(subdir.basename)
            gain_permissions_remove(subdir)
          end
        end
      end
      @cask.metadata_versioned_path.rmdir_if_possible
      @cask.metadata_master_container_path.rmdir_if_possible

      # toplevel staged distribution
      @cask.caskroom_path.rmdir_if_possible
    end

    def purge_caskroom_path
      odebug "Purging all staged versions of Cask #{@cask}"
      gain_permissions_remove(@cask.caskroom_path)
    end
  end
end
