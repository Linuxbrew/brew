module Hbc
  class Container
    class Criteria
      attr_reader :path, :command

      def initialize(path, command)
        @path = path
        @command = command
      end

      def extension(regex)
        path.extname.sub(/^\./, "") =~ Regexp.new(regex.source, regex.options | Regexp::IGNORECASE)
      end

      def magic_number(regex)
        return false if path.directory?

        # 262: length of the longest regex (currently: Hbc::Container::Tar)
        @magic_number ||= File.open(path, "rb") { |f| f.read(262) }
        @magic_number.match?(regex)
      end
    end
  end
end
