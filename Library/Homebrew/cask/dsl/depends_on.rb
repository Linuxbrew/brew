require "rubygems"

module Cask
  class DSL
    class DependsOn < DelegateClass(Hash)
      VALID_KEYS = Set.new [
        :formula,
        :cask,
        :macos,
        :arch,
        :x11,
        :java,
      ].freeze

      VALID_ARCHES = {
        intel:    { type: :intel, bits: 64 },
        # specific
        x86_64:   { type: :intel, bits: 64 },
      }.freeze

      attr_accessor :java
      attr_reader :arch, :cask, :formula, :macos, :x11

      def initialize
        super({})
        @cask ||= []
        @formula ||= []
      end

      def load(**pairs)
        pairs.each do |key, value|
          raise "invalid depends_on key: '#{key.inspect}'" unless VALID_KEYS.include?(key)

          self[key] = send(:"#{key}=", *value)
        end
      end

      def self.coerce_os_release(arg)
        @macos_symbols ||= MacOS::Version::SYMBOLS
        @inverted_macos_symbols ||= @macos_symbols.invert

        begin
          if arg.is_a?(Symbol)
            Gem::Version.new(@macos_symbols.fetch(arg))
          elsif arg =~ /^\s*:?([a-z]\S+)\s*$/i
            Gem::Version.new(@macos_symbols.fetch(Regexp.last_match[1].downcase.to_sym))
          elsif @inverted_macos_symbols.key?(arg)
            Gem::Version.new(arg)
          else
            raise
          end
        rescue
          raise "invalid 'depends_on macos' value: #{arg.inspect}"
        end
      end

      def formula=(*args)
        @formula.concat(args)
      end

      def cask=(*args)
        @cask.concat(args)
      end

      def macos=(*args)
        @macos ||= []
        macos = if args.count == 1 && args.first =~ /^\s*(<|>|[=<>]=)\s*(\S+)\s*$/
          raise "'depends_on macos' comparison expressions cannot be combined" unless @macos.empty?

          operator = Regexp.last_match[1].to_sym
          release = self.class.coerce_os_release(Regexp.last_match[2])
          [[operator, release]]
        else
          raise "'depends_on macos' comparison expressions cannot be combined" if @macos.first.is_a?(Symbol)

          args.map(&self.class.method(:coerce_os_release)).sort
        end
        @macos.concat(macos)
      end

      def arch=(*args)
        @arch ||= []
        arches = args.map do |elt|
          elt.to_s.downcase.sub(/^:/, "").tr("-", "_").to_sym
        end
        invalid_arches = arches - VALID_ARCHES.keys
        raise "invalid 'depends_on arch' values: #{invalid_arches.inspect}" unless invalid_arches.empty?

        @arch.concat(arches.map { |arch| VALID_ARCHES[arch] })
      end

      def x11=(arg)
        raise "invalid 'depends_on x11' value: #{arg.inspect}" unless [true, false].include?(arg)

        @x11 = arg
      end
    end
  end
end
