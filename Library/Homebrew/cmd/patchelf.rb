# Use patchelf to modify the dynamic linker and RPATH of ELF executables

require "formula"

module Homebrew
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

    unless Formula["patchelf"].installed?
      return ofail "patchelf is not installed"
    end

    ARGV.resolved_formulae.each do |f|
      patchelf_formula f
    end
  end
end
