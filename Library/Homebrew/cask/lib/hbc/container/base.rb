module Hbc
  class Container
    class Base
      extend Predicable

      attr_reader :path

      def initialize(cask, path, nested: false)
        @cask = cask
        @path = path
      end

      def extract(to: nil, basename: nil, verbose: false)
        basename ||= path.basename
        unpack_dir = Pathname(to || Dir.pwd).expand_path
        unpack_dir.mkpath
        extract_to_dir(unpack_dir, basename: basename, verbose: verbose)
      end

      def extract_nested_inside(dir, to:, verbose: false)
        children = Pathname.new(dir).children

        nested_container = children[0]

        unless children.count == 1 &&
               !nested_container.directory? &&
               @cask.artifacts.none? { |a| a.is_a?(Artifact::NestedContainer) } &&
               extract_nested_container(nested_container, to: to, verbose: verbose)

          children.each do |src|
            dest = @cask.staged_path.join(src.basename)
            FileUtils.rm_r(dest) if dest.exist?
            FileUtils.mv(src, dest)
          end
        end
      end

      def extract_nested_container(source, to:, verbose: false)
        container = Container.for_path(source)

        return false unless container

        ohai "Extracting nested container #{source.basename}"
        container.new(@cask, source).extract(to: to, verbose: verbose)

        true
      end

      def dependencies
        []
      end
    end
  end
end
