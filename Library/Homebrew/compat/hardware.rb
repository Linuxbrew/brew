module Hardware
  class << self
    def is_32_bit?
      odisabled "Hardware.is_32_bit?", "Hardware::CPU.is_32_bit?"
    end

    def is_64_bit?
      odisabled "Hardware.is_64_bit?", "Hardware::CPU.is_64_bit?"
    end

    def bits
      odisabled "Hardware.bits", "Hardware::CPU.bits"
    end

    def cpu_type
      odisabled "Hardware.cpu_type", "Hardware::CPU.type"
    end

    def cpu_family
      odisabled "Hardware.cpu_family", "Hardware::CPU.family"
    end

    def intel_family
      odisabled "Hardware.intel_family", "Hardware::CPU.family"
    end

    def ppc_family
      odisabled "Hardware.ppc_family", "Hardware::CPU.family"
    end

    def processor_count
      odisabled "Hardware.processor_count", "Hardware::CPU.cores"
    end
  end
end
