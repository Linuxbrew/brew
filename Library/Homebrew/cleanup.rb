require "utils/bottles"
require "formula"
require "hbc/cask_loader"

module CleanupRefinement
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

      stale_formula?(scrub)
    end

    private

    def stale_formula?(scrub)
      return false unless HOMEBREW_CELLAR.directory?

      version = if to_s.match?(Pathname::BOTTLE_EXTNAME_RX)
        begin
          Utils::Bottles.resolve_version(self)
        rescue
          self.version
        end
      else
        self.version
      end

      return false unless version
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

    def update_disk_cleanup_size(path_size)
      @disk_cleanup_size += path_size
    end

    def unremovable_kegs
      @unremovable_kegs ||= []
    end

    def cleanup_formula(formula)
      formula.eligible_kegs_for_cleanup.each(&method(:cleanup_keg))
    end

    def cleanup_cask(cask); end

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

    def cleanup_cache
      return unless cache.directory?
      cache.children.each do |path|
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

        next cleanup_path(path) { path.unlink } if path.stale?(ARGV.switch?("s"))
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

      update_disk_cleanup_size(disk_usage)
    end

    def cleanup_lockfiles
      return unless HOMEBREW_LOCK_DIR.directory?
      candidates = HOMEBREW_LOCK_DIR.children
      lockfiles  = candidates.select(&:file?)
      lockfiles.each do |file|
        next unless file.readable?
        file.open(File::RDWR).flock(File::LOCK_EX | File::LOCK_NB) && file.unlink
      end
    end

    def rm_ds_store
      paths = Queue.new
      %w[Cellar Frameworks Library bin etc include lib opt sbin share var]
        .map { |p| HOMEBREW_PREFIX/p }.each { |p| paths << p if p.exist? }
      workers = (0...Hardware::CPU.cores).map do
        Thread.new do
          Kernel.loop do
            begin
              quiet_system "find", paths.deq(true), "-name", ".DS_Store", "-delete"
            rescue ThreadError
              break # if queue is empty
            end
          end
        end
      end
      workers.map(&:join)
    end
  end
end
