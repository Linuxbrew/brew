module Hardware
  class CPU
    class << self
      undef optimization_flags, type, family, universal_archs, can_run?,
            features, sse4?

      PPC_OPTIMIZATION_FLAGS = {
        g3: "-mcpu=750",
        g4: "-mcpu=7400",
        g4e: "-mcpu=7450",
        g5: "-mcpu=970",
        g5_64: "-mcpu=970 -arch ppc64",
      }.freeze

      def optimization_flags
        OPTIMIZATION_FLAGS.merge(PPC_OPTIMIZATION_FLAGS)
      end

      # These methods use info spewed out by sysctl.
      # Look in <mach/machine.h> for decoding info.
      def type
        case sysctl_int("hw.cputype")
        when 7
          :intel
        when 18
          :ppc
        else
          :dunno
        end
      end

      def family
        if intel?
          case sysctl_int("hw.cpufamily")
          when 0x73d67300 # Yonah: Core Solo/Duo
            :core
          when 0x426f69ef # Merom: Core 2 Duo
            :core2
          when 0x78ea4fbc # Penryn
            :penryn
          when 0x6b5a4cd2 # Nehalem
            :nehalem
          when 0x573B5EEC # Arrandale
            :arrandale
          when 0x5490B78C # Sandy Bridge
            :sandybridge
          when 0x1F65E835 # Ivy Bridge
            :ivybridge
          when 0x10B282DC # Haswell
            :haswell
          when 0x582ed09c # Broadwell
            :broadwell
          when 0x37fc219f # Skylake
            :skylake
          when 0x0f817246 # Kaby Lake
            :kabylake
          else
            :dunno
          end
        elsif ppc?
          case sysctl_int("hw.cpusubtype")
          when 9
            :g3  # PowerPC 750
          when 10
            :g4  # PowerPC 7400
          when 11
            :g4e # PowerPC 7450
          when 100
            # This is the only 64-bit PPC CPU type, so it's useful
            # to distinguish in `brew config` output and in bottle tags
            MacOS.prefer_64_bit? ? :g5_64 : :g5 # PowerPC 970
          else
            :dunno
          end
        end
      end

      # Returns an array that's been extended with ArchitectureListExtension,
      # which provides helpers like #as_arch_flags and #as_cmake_arch_flags.
      def universal_archs
        # Building 64-bit is a no-go on Tiger, and pretty hit or miss on Leopard.
        # Don't even try unless Tigerbrew's experimental 64-bit Leopard support is enabled.
        if MacOS.version <= :leopard && !MacOS.prefer_64_bit?
          [arch_32_bit].extend ArchitectureListExtension
        else
          # Amazingly, this order (64, then 32) matters. It shouldn't, but it
          # does. GCC (some versions? some systems?) can blow up if the other
          # order is used.
          # https://superuser.com/questions/740563/gcc-4-8-on-macos-fails-depending-on-arch-order
          [arch_64_bit, arch_32_bit].extend ArchitectureListExtension
        end
      end

      # Determines whether the current CPU and macOS combination
      # can run an executable of the specified architecture.
      # `arch` is a symbol in the same format returned by
      # Hardware::CPU.family
      def can_run?(arch)
        if Hardware::CPU.intel?
          intel_can_run? arch
        elsif Hardware::CPU.ppc?
          ppc_can_run? arch
        else
          false
        end
      end

      def features
        @features ||= sysctl_n(
          "machdep.cpu.features",
          "machdep.cpu.extfeatures",
          "machdep.cpu.leaf7_features",
        ).split(" ").map { |s| s.downcase.to_sym }
      end

      def sse4?
        sysctl_bool("hw.optional.sse4_1")
      end

      def extmodel
        sysctl_int("machdep.cpu.extmodel")
      end

      def aes?
        sysctl_bool("hw.optional.aes")
      end

      def altivec?
        sysctl_bool("hw.optional.altivec")
      end

      def avx?
        sysctl_bool("hw.optional.avx1_0")
      end

      def avx2?
        sysctl_bool("hw.optional.avx2_0")
      end

      def sse3?
        sysctl_bool("hw.optional.sse3")
      end

      def ssse3?
        sysctl_bool("hw.optional.supplementalsse3")
      end

      def sse4_2?
        sysctl_bool("hw.optional.sse4_2")
      end

      private

      def sysctl_bool(key)
        sysctl_int(key) == 1
      end

      def sysctl_int(key)
        sysctl_n(key).to_i
      end

      def sysctl_n(*keys)
        (@properties ||= {}).fetch(keys) do
          @properties[keys] = Utils.popen_read("/usr/sbin/sysctl", "-n", *keys)
        end
      end

      def intel_can_run?(arch)
        case arch
        when *PPC_32BIT_ARCHS
          # Rosetta is still available
          MacOS.version < :lion
        when *PPC_64BIT_ARCHS
          # Rosetta never supported PPC64
          false
        when *INTEL_64BIT_ARCHS
          Hardware::CPU.is_64_bit?
        when *INTEL_32BIT_ARCHS
          true
        else # dunno
          false
        end
      end

      def ppc_can_run?(arch)
        case arch
        when *PPC_32BIT_ARCHS
          true
        when *PPC_64BIT_ARCHS
          Hardware::CPU.is_64_bit?
        else
          # Intel is never supported
          false
        end
      end
    end
  end
end
