require "extend/os/hardware"

module ArchitectureListExtension
  def ppc?
    (Hardware::CPU::PPC_32BIT_ARCHS+Hardware::CPU::PPC_64BIT_ARCHS).any? { |a| include? a }
  end

  def as_arch_flags
    ""
  end

  def as_cmake_arch_flags
    ""
  end
end
