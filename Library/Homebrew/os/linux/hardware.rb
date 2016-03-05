module LinuxCPUs
  OPTIMIZATION_FLAGS = {
    :penryn => "-march=core2 -msse4.1",
    :core2 => "-march=core2",
    :core => "-march=prescott",
    :arm => "",
  }.freeze
  def optimization_flags
    OPTIMIZATION_FLAGS
  end

  # Linux supports x86 only, and universal archs do not apply
  def arch_32_bit
    :i386
  end

  def arch_64_bit
    :x86_64
  end

  def universal_archs
    [].extend ArchitectureListExtension
  end

  def cpuinfo
    @cpuinfo ||= File.read("/proc/cpuinfo")
  end

  def type
    @type ||= if cpuinfo =~ /Intel|AMD/
      :intel
    elsif cpuinfo =~ /ARM|Marvell/
      :arm
    else
      :dunno
    end
  end

  def family
    if intel?
      # See https://software.intel.com/en-us/articles/intel-architecture-and-processor-identification-with-cpuid-model-and-family-numbers
      cpu_family = cpuinfo[/^cpu family\s*: ([0-9]+)/, 1].to_i
      cpu_model = cpuinfo[/^model\s*: ([0-9]+)/, 1].to_i
      cpu_family_model = "0x" + ((cpu_family << 8) | cpu_model).to_s(16)
      case cpu_family
      when 0x06
        case cpu_model
        when 0x3a, 0x3e
          :ivybridge
        when 0x2a, 0x2d
          :sandybridge
        when 0x25, 0x2c, 0x2f
          :arrandale # Westmere
        when 0x1e, 0x1a, 0x2e
          :nehalem
        when 0x17, 0x1d
          :penryn
        when 0x0f, 0x16
          :core2 # Merom
        when 0x0d
          :dothan
        when 0x36, 0x26, 0x1c
          :atom
        when 0x3c, 0x3f, 0x46
          :haswell
        when 0x3d, 0x47, 0x4f, 0x56
          :broadwell
        else
          cpu_family_model
        end
      when 0x0f
        case cpu_model
        when 0x06, 0x03, 0x04
          :core # Presler and Prescott
        else
          cpu_family_model
        end
      else
        cpu_family_model
      end
    elsif arm?
      :arm
    end
  end
  alias_method :intel_family, :family

  def cores
    cpuinfo.scan(/^processor/).size
  end

  def flags
    @flags ||= cpuinfo[/^(flags|Features).*/, 0].split
  end

  # Compatibility with Mac method, which returns lowercase symbols
  # instead of strings
  def features
    @features ||= flags[1..-1].map(&:intern)
  end

  %w[aes altivec avx avx2 lm sse3 ssse3 sse4 sse4_2].each do |flag|
    define_method(flag + "?") { flags.include? flag }
  end
  alias_method :is_64_bit?, :lm?

  def bits
    is_64_bit? ? 64 : 32
  end
end
