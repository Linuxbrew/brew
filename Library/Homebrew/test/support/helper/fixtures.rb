module Test
  module Helper
    module Fixtures
      def dylib_path(name)
        Pathname.new("#{TEST_FIXTURE_DIR}/mach/#{name}.dylib")
      end

      def bundle_path(name)
        Pathname.new("#{TEST_FIXTURE_DIR}/mach/#{name}.bundle")
      end
    end
  end
end
