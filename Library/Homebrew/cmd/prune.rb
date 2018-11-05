#:  * `prune` [`--dry-run`]:
#:    Remove dead symlinks from the Homebrew prefix. This is generally not
#:    needed, but can be useful when doing DIY installations.
#:
#:    If `--dry-run` or `-n` is passed, show what would be removed, but do not
#:    actually remove anything.

require "keg"
require "cli_parser"

module Homebrew
  module_function

  def prune_args
    Homebrew::CLI::Parser.new do
      usage_banner <<~EOS
        `prune` [<options>]

        Remove dead symlinks from the Homebrew prefix. This is generally not
        needed, but can be useful when doing DIY installations.
      EOS
      switch "-n", "--dry-run",
        description: "Show what would be removed, but do not actually remove anything."
      switch :verbose
      switch :debug
    end
  end

  def prune
    prune_args.parse

    ObserverPathnameExtension.reset_counts!

    dirs = []

    Keg::MUST_EXIST_SUBDIRECTORIES.each do |dir|
      next unless dir.directory?

      dir.find do |path|
        path.extend(ObserverPathnameExtension)
        if path.symlink?
          unless path.resolved_path_exists?
            if path.to_s =~ Keg::INFOFILE_RX
              path.uninstall_info unless ARGV.dry_run?
            end

            if args.dry_run?
              puts "Would remove (broken link): #{path}"
            else
              path.unlink
            end
          end
        elsif path.directory? && !Keg::MUST_EXIST_SUBDIRECTORIES.include?(path)
          dirs << path
        end
      end
    end

    dirs.reverse_each do |d|
      if ARGV.dry_run? && d.children.empty?
        puts "Would remove (empty directory): #{d}"
      else
        d.rmdir_if_possible
      end
    end

    return if args.dry_run?

    if ObserverPathnameExtension.total.zero?
      puts "Nothing pruned" if args.verbose?
    else
      n, d = ObserverPathnameExtension.counts
      print "Pruned #{n} symbolic links "
      print "and #{d} directories " if d.positive?
      puts "from #{HOMEBREW_PREFIX}"
    end
  end
end
