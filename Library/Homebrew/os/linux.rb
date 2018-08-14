module OS
  # Define OS::Mac on Linux for formula API compatibility.
  module Mac
    module_function

    ::MacOS = self # rubocop:disable Naming/ConstantName

    raise "Loaded OS::Linux on generic OS!" if ENV["HOMEBREW_TEST_GENERIC_OS"]

    def prefer_64_bit?
      Hardware::CPU.is_64_bit?
    end

    def version
      Version::NULL
    end

    def full_version
      Version::NULL
    end

    module Xcode
      module_function

      def version
        Version::NULL
      end
    end
  end
end
