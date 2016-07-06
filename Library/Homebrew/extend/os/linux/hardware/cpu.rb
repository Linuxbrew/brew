module Hardware
  class CPU
    class << self
      def universal_archs
        [].extend ArchitectureListExtension
      end

      def cpuinfo
        @cpuinfo ||= File.read("/proc/cpuinfo")
      end

      def type
        @type ||= if cpuinfo =~ /Intel|AMD/
          :intel
        else
          :dunno
        end
      end

      def family
        cpuinfo[/^cpu family\s*: ([0-9]+)/, 1].to_i
      end
      alias_method :intel_family, :family

      def cores
        cpuinfo.scan(/^processor/).size
      end

      def flags
        @flags ||= cpuinfo[/^flags.*/, 0].split
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
  end
end
