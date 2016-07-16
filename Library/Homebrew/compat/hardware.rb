module Hardware
  class << self
    def is_32_bit?
      odeprecated "Hardware.is_32_bit?", "Hardware::CPU.is_32_bit?"
      !CPU.is_64_bit?
    end

    def is_64_bit?
      odeprecated "Hardware.is_64_bit?", "Hardware::CPU.is_64_bit?"
      CPU.is_64_bit?
    end

    def bits
      odeprecated "Hardware.bits", "Hardware::CPU.bits"
      Hardware::CPU.bits
    end

    def cpu_type
      odeprecated "Hardware.cpu_type", "Hardware::CPU.type"
      Hardware::CPU.type
    end

    def cpu_family
      odeprecated "Hardware.cpu_family", "Hardware::CPU.family"
      Hardware::CPU.family
    end

    def intel_family
      odeprecated "Hardware.intel_family", "Hardware::CPU.family"
      Hardware::CPU.family
    end

    def ppc_family
      odeprecated "Hardware.ppc_family", "Hardware::CPU.family"
      Hardware::CPU.family
    end

    def processor_count
      odeprecated "Hardware.processor_count", "Hardware::CPU.cores"
      Hardware::CPU.cores
    end
  end
end
