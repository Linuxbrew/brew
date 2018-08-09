require "utils/bottles"
require "formula"
require "hbc/cask_loader"

module CleanupRefinement
  LATEST_CASK_DAYS = 7

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
      directory? && ["glide_home", "java_cache", "npm_cache"].include?(basename.to_s)
    end

    def prune?(days)
      return false unless days
      return true if days.zero?

      # TODO: Replace with ActiveSupport's `.days.ago`.
      mtime < ((@time ||= Time.now) - days * 60 * 60 * 24)
    end

    def stale?(scrub = false)
      return false unless file?

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

      version ||= basename.to_s[/\A.*--(.*?)#{Regexp.escape(extname)}/, 1]

      return false unless version

      version = Version.parse(version)

      return false unless (name = basename.to_s[/\A(.*?)\-\-?(?:#{Regexp.escape(version)})/, 1])

      formula = begin
        Formulary.from_rack(HOMEBREW_CELLAR/name)
      rescue FormulaUnavailableError, TapFormulaAmbiguityError, TapFormulaWithOldnameAmbiguityError
        return false
      end

      if version.is_a?(PkgVersion)
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
        Hbc::CaskLoader.load(name)
      rescue Hbc::CaskUnavailableError
        return false
      end

      unless basename.to_s.match?(/\A#{Regexp.escape(name)}\-\-#{Regexp.escape(cask.version)}\b/)
        return true
      end

      return true if scrub && !cask.versions.include?(cask.version)

      if cask.version.latest?
        # TODO: Replace with ActiveSupport's `.days.ago`.
        return mtime < ((@time ||= Time.now) - LATEST_CASK_DAYS * 60 * 60 * 24)
      end

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
    end

    def clean!
      if args.empty?
        Formula.installed.each do |formula|
          cleanup_formula(formula)
        end
        cleanup_cache
        cleanup_logs
        return if dry_run?
        cleanup_lockfiles
        rm_ds_store
      else
        args.each do |arg|
          formula = begin
            Formula[arg]
          rescue FormulaUnavailableError, TapFormulaAmbiguityError, TapFormulaWithOldnameAmbiguityError
            nil
          end

          cask = begin
            Hbc::CaskLoader.load(arg)
          rescue Hbc::CaskUnavailableError
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

    def cleanup_cache(entries = nil)
      entries ||= [cache, cache/"Cask"].select(&:directory?).flat_map(&:children)

      entries.each do |path|
        next cleanup_path(path) { path.unlink } if path.incomplete?
        next cleanup_path(path) { FileUtils.rm_rf path } if path.nested_cache?

        if path.prune?(days)
          if path.file?
            cleanup_path(path) { path.unlink }
          elsif path.directory? && path.to_s.include?("--")
            cleanup_path(path) { FileUtils.rm_rf path }
          end
          next
        end

        next cleanup_path(path) { path.unlink } if path.stale?(scrub?)
      end
    end

    def cleanup_path(path)
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
      return unless HOMEBREW_LOCK_DIR.directory?

      if lockfiles.empty?
        lockfiles = HOMEBREW_LOCK_DIR.children.select(&:file?)
      end

      lockfiles.each do |file|
        next unless file.readable?
        next unless file.open(File::RDWR).flock(File::LOCK_EX | File::LOCK_NB)
        cleanup_path(file) { file.unlink }
      end
    end

    def rm_ds_store(dirs = nil)
      dirs ||= %w[Caskroom Cellar Frameworks Library bin etc include lib opt sbin share var]
               .map { |path| HOMEBREW_PREFIX/path }

      dirs.select(&:directory?).each.parallel do |dir|
        system_command "find", args: [dir, "-name", ".DS_Store", "-delete"], print_stderr: false
      end
    end
  end
end
