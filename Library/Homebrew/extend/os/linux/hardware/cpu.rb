module Hardware
  class CPU
    class << self
      def cpuinfo
        @cpuinfo ||= File.read("/proc/cpuinfo")
      end

      def family
        return :arm if arm?
        return :ppc if ppc?
        return :dunno unless intel?

        # See https://software.intel.com/en-us/articles/intel-architecture-and-processor-identification-with-cpuid-model-and-family-numbers
        # and https://github.com/llvm-mirror/llvm/blob/master/lib/Support/Host.cpp
        # and https://en.wikipedia.org/wiki/List_of_Intel_CPU_microarchitectures#Roadmap
        cpu_family = cpuinfo[/^cpu family\s*: ([0-9]+)/, 1].to_i
        cpu_model = cpuinfo[/^model\s*: ([0-9]+)/, 1].to_i
        unknown = :"unknown_0x#{cpu_family.to_s(16)}_0x#{cpu_model.to_s(16)}"
        case cpu_family
        when 0x06
          case cpu_model
          when 0x3a, 0x3e
            :ivybridge
          when 0x2a, 0x2d
            :sandybridge
          when 0x25, 0x2c, 0x2f
            :westmere
          when 0x1e, 0x1a, 0x2e
            :nehalem
          when 0x17, 0x1d
            :penryn
          when 0x0f, 0x16
            :merom
          when 0x0d
            :dothan
          when 0x36, 0x26, 0x1c
            :atom
          when 0x3c, 0x3f, 0x46
            :haswell
          when 0x3d, 0x47, 0x4f, 0x56
            :broadwell
          when 0x4e, 0x55, 0x5e, 0x8e, 0x9e
            :skylake
          else
            unknown
          end
        when 0x0f
          case cpu_model
          when 0x06
            :presler
          when 0x03, 0x04
            :prescott
          else
            unknown
          end
        else
          unknown
        end
      end

      def flags
        @flags ||= cpuinfo[/^(flags|Features).*/, 0]&.split
        @flags ||= []
      end

      # Compatibility with Mac method, which returns lowercase symbols
      # instead of strings
      def features
        @features ||= flags[1..-1].map(&:intern)
      end

      %w[aes altivec avx avx2 lm ssse3 sse4_2].each do |flag|
        define_method(flag + "?") { flags.include? flag }
      end

      def sse3?
        flags.include?("pni") || flags.include?("sse3")
      end

      def sse4?
        flags.include? "sse4_1"
      end
    end
  end
end
