require "utils/bottles"
require "formula"
require "cask/cask_loader"
require "set"

module CleanupRefinement
  LATEST_CASK_OUTDATED = 7.days.ago

  refine Enumerator do
    def parallel
      queue = Queue.new

      each do |element|
        queue.enq(element)
      end

      workers = (0...Hardware::CPU.cores).map do
        Thread.new do
          Kernel.loop do
            begin
              yield queue.deq(true)
            rescue ThreadError
              break # if queue is empty
            end
          end
        end
      end

      workers.each(&:join)
    end
  end

  refine Pathname do
    def incomplete?
      extname.end_with?(".incomplete")
    end

    def nested_cache?
      directory? && %w[cargo_cache go_cache glide_home java_cache npm_cache gclient_cache].include?(basename.to_s)
    end

    def go_cache_directory?
      # Go makes its cache contents read-only to ensure cache integrity,
      # which makes sense but is something we need to undo for cleanup.
      directory? && %w[go_cache].include?(basename.to_s)
    end

    def prune?(days)
      return false unless days
      return true if days.zero?

      return true if symlink? && !exist?

      mtime < days.days.ago
    end

    def stale?(scrub = false)
      return false unless resolved_path.file?

      stale_formula?(scrub) || stale_cask?(scrub)
    end

    private

    def stale_formula?(scrub)
      return false unless HOMEBREW_CELLAR.directory?

      version = if to_s.match?(Pathname::BOTTLE_EXTNAME_RX)
        begin
          Utils::Bottles.resolve_version(self)
        rescue
          nil
        end
      end

      version ||= basename.to_s[/\A.*(?:\-\-.*?)*\-\-(.*?)#{Regexp.escape(extname)}\Z/, 1]
      version ||= basename.to_s[/\A.*\-\-?(.*?)#{Regexp.escape(extname)}\Z/, 1]

      return false unless version

      version = Version.new(version)

      return false unless formula_name = basename.to_s[/\A(.*?)(?:\-\-.*?)*\-\-?(?:#{Regexp.escape(version)})/, 1]

      formula = begin
        Formulary.from_rack(HOMEBREW_CELLAR/formula_name)
      rescue FormulaUnavailableError, TapFormulaAmbiguityError, TapFormulaWithOldnameAmbiguityError
        return false
      end

      resource_name = basename.to_s[/\A.*?\-\-(.*?)\-\-?(?:#{Regexp.escape(version)})/, 1]

      if resource_name == "patch"
        patch_hashes = formula.stable&.patches&.select(&:external?)&.map(&:resource)&.map(&:version)
        return true unless patch_hashes&.include?(Checksum.new(:sha256, version.to_s))
      elsif resource_name && resource_version = formula.stable&.resources&.dig(resource_name)&.version
        return true if resource_version != version
      elsif version.is_a?(PkgVersion)
        return true if formula.pkg_version > version
      elsif formula.version > version
        return true
      end

      return true if scrub && !formula.installed?

      return true if Utils::Bottles.file_outdated?(formula, self)

      false
    end

    def stale_cask?(scrub)
      return false unless name = basename.to_s[/\A(.*?)\-\-/, 1]

      cask = begin
        Cask::CaskLoader.load(name)
      rescue Cask::CaskUnavailableError
        return false
      end

      unless basename.to_s.match?(/\A#{Regexp.escape(name)}\-\-#{Regexp.escape(cask.version)}\b/)
        return true
      end

      return true if scrub && !cask.versions.include?(cask.version)

      return mtime < LATEST_CASK_OUTDATED if cask.version.latest?

      false
    end
  end
end

using CleanupRefinement

module Homebrew
  class Cleanup
    extend Predicable

    attr_predicate :dry_run?, :scrub?
    attr_reader :args, :days, :cache
    attr_reader :disk_cleanup_size

    def initialize(*args, dry_run: false, scrub: false, days: nil, cache: HOMEBREW_CACHE)
      @disk_cleanup_size = 0
      @args = args
      @dry_run = dry_run
      @scrub = scrub
      @days = days
      @cache = cache
      @cleaned_up_paths = Set.new
    end

    def clean!
      if args.empty?
        Formula.installed.sort_by(&:name).each do |formula|
          cleanup_formula(formula)
        end
        cleanup_cache
        cleanup_logs
        cleanup_portable_ruby
        cleanup_lockfiles
        return if dry_run?

        cleanup_old_cache_db
        rm_ds_store
      else
        args.each do |arg|
          formula = begin
            Formulary.resolve(arg)
          rescue FormulaUnavailableError, TapFormulaAmbiguityError, TapFormulaWithOldnameAmbiguityError
            nil
          end

          cask = begin
            Cask::CaskLoader.load(arg)
          rescue Cask::CaskUnavailableError
            nil
          end

          cleanup_formula(formula) if formula
          cleanup_cask(cask) if cask
        end
      end
    end

    def unremovable_kegs
      @unremovable_kegs ||= []
    end

    def cleanup_formula(formula)
      formula.eligible_kegs_for_cleanup.each(&method(:cleanup_keg))
      cleanup_cache(Pathname.glob(cache/"#{formula.name}--*"))
      rm_ds_store([formula.rack])
      cleanup_lockfiles(FormulaLock.new(formula.name).path)
    end

    def cleanup_cask(cask)
      cleanup_cache(Pathname.glob(cache/"Cask/#{cask.token}--*"))
      rm_ds_store([cask.caskroom_path])
      cleanup_lockfiles(CaskLock.new(cask.token).path)
    end

    def cleanup_keg(keg)
      cleanup_path(keg) { keg.uninstall }
    rescue Errno::EACCES => e
      opoo e.message
      unremovable_kegs << keg
    end

    DEFAULT_LOG_DAYS = 14

    def cleanup_logs
      return unless HOMEBREW_LOGS.directory?

      HOMEBREW_LOGS.subdirs.each do |dir|
        cleanup_path(dir) { dir.rmtree } if dir.prune?(days || DEFAULT_LOG_DAYS)
      end
    end

    def cleanup_unreferenced_downloads
      return if dry_run?
      return unless (cache/"downloads").directory?

      downloads = (cache/"downloads").children

      referenced_downloads = [cache, cache/"Cask"].select(&:directory?)
                                                  .flat_map(&:children)
                                                  .select(&:symlink?)
                                                  .map(&:resolved_path)

      (downloads - referenced_downloads).each do |download|
        if download.incomplete?
          begin
            LockFile.new(download.basename).with_lock do
              download.unlink
            end
          rescue OperationInProgressError
            # Skip incomplete downloads which are still in progress.
            next
          end
        else
          download.unlink
        end
      end
    end

    def cleanup_cache(entries = nil)
      entries ||= [cache, cache/"Cask"].select(&:directory?).flat_map(&:children)

      entries.each do |path|
        FileUtils.chmod_R 0755, path if path.go_cache_directory? && !dry_run?
        next cleanup_path(path) { path.unlink } if path.incomplete?
        next cleanup_path(path) { FileUtils.rm_rf path } if path.nested_cache?

        if path.prune?(days)
          if path.file? || path.symlink?
            cleanup_path(path) { path.unlink }
          elsif path.directory? && path.to_s.include?("--")
            cleanup_path(path) { FileUtils.rm_rf path }
          end
          next
        end

        next cleanup_path(path) { path.unlink } if path.stale?(scrub?)
      end

      cleanup_unreferenced_downloads
    end

    def cleanup_path(path)
      return unless @cleaned_up_paths.add?(path)

      disk_usage = path.disk_usage

      if dry_run?
        puts "Would remove: #{path} (#{path.abv})"
      else
        puts "Removing: #{path}... (#{path.abv})"
        yield
      end

      @disk_cleanup_size += disk_usage
    end

    def cleanup_lockfiles(*lockfiles)
      return if dry_run?

      if lockfiles.empty? && HOMEBREW_LOCKS.directory?
        lockfiles = HOMEBREW_LOCKS.children.select(&:file?)
      end

      lockfiles.each do |file|
        next unless file.readable?
        next unless file.open(File::RDWR).flock(File::LOCK_EX | File::LOCK_NB)

        begin
          file.unlink
        ensure
          file.open(File::RDWR).flock(File::LOCK_UN) if file.exist?
        end
      end
    end

    def cleanup_portable_ruby
      system_ruby_version =
        Utils.popen_read("/usr/bin/ruby", "-e", "puts RUBY_VERSION")
             .chomp
      use_system_ruby = (
        Gem::Version.new(system_ruby_version) >= Gem::Version.new(RUBY_VERSION)
      ) && ENV["HOMEBREW_FORCE_VENDOR_RUBY"].nil?
      vendor_path = HOMEBREW_LIBRARY/"Homebrew/vendor"
      portable_ruby_version_file = vendor_path/"portable-ruby-version"
      portable_ruby_version = if portable_ruby_version_file.exist?
        portable_ruby_version_file.read
                                  .chomp
      end

      portable_ruby_path = vendor_path/"portable-ruby"
      portable_ruby_glob = "#{portable_ruby_path}/*.*"
      Pathname.glob(portable_ruby_glob).each do |path|
        next if !use_system_ruby && portable_ruby_version == path.basename.to_s
        if dry_run?
          puts "Would remove: #{path} (#{path.abv})"
        else
          FileUtils.rm_rf path
        end
      end

      return unless Dir.glob(portable_ruby_glob).empty?
      return unless portable_ruby_path.exist?

      bundler_path = vendor_path/"bundle/ruby"
      if dry_run?
        puts "Would remove: #{bundler_path} (#{bundler_path.abv})"
        puts "Would remove: #{portable_ruby_path} (#{portable_ruby_path.abv})"
      else
        FileUtils.rm_rf [bundler_path, portable_ruby_path]
      end
    end

    def cleanup_old_cache_db
      FileUtils.rm_rf [
        cache/"desc_cache.json",
        cache/"linkage.db",
        cache/"linkage.db.db",
      ]
    end

    def rm_ds_store(dirs = nil)
      dirs ||= begin
        Keg::MUST_EXIST_DIRECTORIES + [
          HOMEBREW_PREFIX/"Caskroom",
        ]
      end
      dirs.select(&:directory?).each.parallel do |dir|
        system_command "find",
          args:         [dir, "-name", ".DS_Store", "-delete"],
          print_stderr: false
      end
    end
  end
end
