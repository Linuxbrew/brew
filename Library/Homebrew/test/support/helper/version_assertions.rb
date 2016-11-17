require "rubygems"

module Test
  module Helper
    module VersionAssertions
      def version(v)
        Version.create(v)
      end

      def assert_version_equal(expected, actual)
        assert_equal Version.create(expected), actual
      end

      def assert_version_detected(expected, url, specs = {})
        assert_equal expected, Version.detect(url, specs).to_s
      end

      def assert_version_nil(url)
        assert Version.parse(url).null?
      end
    end
  end
end
