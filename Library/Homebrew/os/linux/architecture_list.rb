require "extend/os/hardware"

module ArchitectureListExtension
  # @private
  def fat?
    false
  end

  # @private
  def universal?
    false
  end

  def ppc?
    (Hardware::CPU::PPC_32BIT_ARCHS+Hardware::CPU::PPC_64BIT_ARCHS).any? { |a| include? a }
  end

  # @private
  def remove_ppc!
    (Hardware::CPU::PPC_32BIT_ARCHS+Hardware::CPU::PPC_64BIT_ARCHS).each { |a| delete a }
  end

  def as_arch_flags
    ""
  end

  def as_cmake_arch_flags
    ""
  end
end
