# Use patchelf to modify the dynamic linker and RPATH of ELF executables

require "formula"

module Homebrew
  def self.ensure_patchelf_installed!
    return if Formula["patchelf"].installed?
    require "cmd/install"
    oh1 "Installing patchelf"
    Homebrew.perform_preinstall_checks
    Homebrew.install_formula(Formula["patchelf"])
  end

  def patchelf_formula f
    unless f.installed?
      return ofail "Formula not installed or up-to-date: #{f.full_name}"
    end

    ohai "Fixing up #{f.full_name}..."
    keg = Keg.new(f.prefix)
    keg.lock do
      keg.relocate_install_names Keg::PREFIX_PLACEHOLDER, HOMEBREW_PREFIX,
        Keg::CELLAR_PLACEHOLDER, HOMEBREW_CELLAR
    end
  end

  def patchelf
    raise FormulaUnspecifiedError if ARGV.named.empty?

    ensure_patchelf_installed!

    ARGV.resolved_formulae.each do |f|
      patchelf_formula f
    end
  end
end
