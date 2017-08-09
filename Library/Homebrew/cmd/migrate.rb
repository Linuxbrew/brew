#:  * `migrate` [`--force`] <formulae>:
#:    Migrate renamed packages to new name, where <formulae> are old names of
#:    packages.
#:
#:    If `--force` (or `-f`) is passed, then treat installed <formulae> and passed <formulae>
#:    like if they are from same taps and migrate them anyway.

require "migrator"

module Homebrew
  module_function

  def migrate
    raise FormulaUnspecifiedError if ARGV.named.empty?

    ARGV.resolved_formulae.each do |f|
      if f.oldname
        unless (rack = HOMEBREW_CELLAR/f.oldname).exist? && !rack.subdirs.empty?
          raise NoSuchKegError, f.oldname
        end
        raise "#{rack} is a symlink" if rack.symlink?
      end

      migrator = Migrator.new(f)
      migrator.migrate
    end
  end
end
