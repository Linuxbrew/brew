require "keg"

class FormulaPin
  def initialize(f)
    @f = f
  end

  def path
    HOMEBREW_PINNED_KEGS/@f.name
  end

  def pin_at(version)
    HOMEBREW_PINNED_KEGS.mkpath
    version_path = @f.rack.join(version)
    path.make_relative_symlink(version_path) unless pinned? || !version_path.exist?
  end

  def pin
    pin_at(@f.installed_kegs.map(&:version).max)
  end

  def unpin
    path.unlink if pinned?
    HOMEBREW_PINNED_KEGS.rmdir_if_possible
  end

  def pinned?
    path.symlink?
  end

  def pinnable?
    !@f.installed_prefixes.empty?
  end

  def pinned_version
    Keg.new(path.resolved_path).version if pinned?
  end
end
