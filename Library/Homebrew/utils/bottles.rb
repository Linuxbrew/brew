require "tab"
require "extend/ARGV"

module Utils
  class Bottles
    class << self
      def tag
        @bottle_tag ||= "#{ENV["HOMEBREW_SYSTEM"]}_#{ENV["HOMEBREW_PROCESSOR"]}".downcase.to_sym
      end

      def built_as?(f)
        return false unless f.installed?
        tab = Tab.for_keg(f.installed_prefix)
        tab.built_as_bottle
      end

      def file_outdated?(f, file)
        filename = file.basename.to_s
        return unless f.bottle && filename.match(Pathname::BOTTLE_EXTNAME_RX)

        bottle_ext = filename[native_regex, 1]
        bottle_url_ext = f.bottle.url[native_regex, 1]

        bottle_ext && bottle_url_ext && bottle_ext != bottle_url_ext
      end

      def native_regex
        /(\.#{Regexp.escape(tag.to_s)}\.bottle\.(\d+\.)?tar\.gz)$/o
      end

      def receipt_path(bottle_file)
        Utils.popen_read("tar", "-tzf", bottle_file).lines.map(&:chomp).find do |line|
          line =~ %r{.+/.+/INSTALL_RECEIPT.json}
        end
      end

      def resolve_formula_names(bottle_file)
        receipt_file_path = receipt_path bottle_file
        receipt_file = Utils.popen_read("tar", "-xOzf", bottle_file, receipt_file_path)
        name = receipt_file_path.split("/").first
        tap = Tab.from_file_content(receipt_file, "#{bottle_file}/#{receipt_file_path}").tap

        if tap.nil? || tap.core_tap?
          full_name = name
        else
          full_name = "#{tap}/#{name}"
        end

        [name, full_name]
      end

      def resolve_version(bottle_file)
        PkgVersion.parse receipt_path(bottle_file).split("/")[1]
      end
    end

    class Bintray
      def self.package(formula_name)
        package_name = formula_name.to_s.dup
        package_name.tr!("+", "x")
        package_name.sub!(/(.)@(\d)/, "\\1:\\2") # Handle foo@1.2 style formulae.
        package_name
      end

      def self.repository(tap = nil)
        if tap.nil? || tap.core_tap?
          "bottles"
        else
          "bottles-#{tap.repo}"
        end
      end
    end

    class Collector
      def initialize
        @checksums = {}
      end

      def fetch_checksum_for(tag)
        tag = find_matching_tag(tag)
        return self[tag], tag if tag
      end

      def keys
        @checksums.keys
      end

      def [](key)
        @checksums[key]
      end

      def []=(key, value)
        @checksums[key] = value
      end

      def key?(key)
        @checksums.key?(key)
      end

      private

      def find_matching_tag(tag)
        tag if key?(tag)
      end
    end
  end
end

require "extend/os/bottles"
