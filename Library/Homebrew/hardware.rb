module Hardware
  class CPU
    INTEL_32BIT_ARCHS = [:i386].freeze
    INTEL_64BIT_ARCHS = [:x86_64].freeze
    PPC_32BIT_ARCHS   = [:ppc, :ppc32, :ppc7400, :ppc7450, :ppc970].freeze
    PPC_64BIT_ARCHS   = [:ppc64].freeze

    class << self
      OPTIMIZATION_FLAGS = {
        core2: "-march=core2",
        core:  "-march=prescott",
        armv6: "-march=armv6",
        armv8: "-march=armv8-a",
      }.freeze

      def optimization_flags
        OPTIMIZATION_FLAGS
      end

      def arch_32_bit
        if arm?
          :arm
        elsif intel?
          :i386
        elsif ppc?
          :ppc32
        else
          :dunno
        end
      end

      def arch_64_bit
        if arm?
          :arm64
        elsif intel?
          :x86_64
        elsif ppc?
          :ppc64
        else
          :dunno
        end
      end

      def arch
        case bits
        when 32
          arch_32_bit
        when 64
          arch_64_bit
        else
          :dunno
        end
      end

      def universal_archs
        [arch].extend ArchitectureListExtension
      end

      def type
        case RUBY_PLATFORM
        when /x86_64/, /i\d86/ then :intel
        when /arm/ then :arm
        when /ppc\d+/ then :ppc
        else :dunno
        end
      end

      def family
        :dunno
      end

      def cores
        return @cores if @cores

        @cores = Utils.popen_read("getconf", "_NPROCESSORS_ONLN").chomp.to_i
        @cores = 1 unless $CHILD_STATUS.success?
        @cores
      end

      def bits
        @bits ||= case RUBY_PLATFORM
        when /x86_64/, /ppc64/, /aarch64|arm64/ then 64
        when /i\d86/, /ppc/, /arm/ then 32
        end
      end

      def sse4?
        RUBY_PLATFORM.to_s.include?("x86_64")
      end

      def is_32_bit?
        bits == 32
      end

      def is_64_bit?
        bits == 64
      end

      def intel?
        type == :intel
      end

      def ppc?
        type == :ppc
      end

      def arm?
        type == :arm
      end

      def features
        []
      end

      def feature?(name)
        features.include?(name)
      end

      def can_run?(arch)
        if is_32_bit?
          arch_32_bit == arch
        elsif intel?
          (INTEL_32BIT_ARCHS + INTEL_64BIT_ARCHS).include?(arch)
        elsif ppc?
          (PPC_32BIT_ARCHS + PPC_64BIT_ARCHS).include?(arch)
        else
          false
        end
      end
    end
  end

  def self.cores_as_words
    case Hardware::CPU.cores
    when 1 then "single"
    when 2 then "dual"
    when 4 then "quad"
    when 6 then "hexa"
    when 8 then "octa"
    when 12 then "dodeca"
    else
      Hardware::CPU.cores
    end
  end

  def self.oldest_cpu
    if Hardware::CPU.intel?
      if Hardware::CPU.is_64_bit?
        :core2
      else
        :core
      end
    elsif Hardware::CPU.arm?
      if Hardware::CPU.is_64_bit?
        :armv8
      else
        :armv6
      end
    else
      Hardware::CPU.family
    end
  end
end

require "extend/os/hardware"
