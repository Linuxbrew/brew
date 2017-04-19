module Hardware
  class CPU
    class << self
      OPTIMIZATION_FLAGS_LINUX = {
        core2: "-march=core2",
        core: "-march=prescott",
        arm: "-march=armv6",
        dunno: "-march=native",
      }.freeze

      def optimization_flags
        OPTIMIZATION_FLAGS_LINUX
      end

      def universal_archs
        arch = case bits
        when 32
          arch_32_bit
        when 64
          arch_64_bit
        end
        [arch].compact.extend ArchitectureListExtension
      end

      def cpuinfo
        @cpuinfo ||= File.read("/proc/cpuinfo")
      end

      def type
        @type ||= case Utils.popen_read("uname", "-m").chomp
        when "x86_64", "amd64", /^i\d86$/
          :intel
        when /^arm/
          :arm
        else
          :dunno
        end
      end

      def family
        return :arm if arm?
        return :dunno unless intel?
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
          when 0x5e
            :skylake
          when 0x8e
            :kabylake
          else
            cpu_family_model
          end
        when 0x0f
          case cpu_model
          when 0x06
            :presler
          when 0x03, 0x04
            :prescott
          else
            cpu_family_model
          end
        else
          cpu_family_model
        end
      end

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

      def bits
        Utils.popen_read("getconf", "LONG_BIT").chomp.to_i
      end

      def arch_32_bit
        intel? ? :i386 : :arm
      end

      def arch_64_bit
        intel? ? :x86_64 : :arm64
      end
    end
  end
end
