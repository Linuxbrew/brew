module Utils
  class Bottles
    class << self
      def tag
        if MacOS.version >= :lion
          MacOS.cat
        elsif MacOS.version == :snow_leopard
          Hardware::CPU.is_64_bit? ? :snow_leopard : :snow_leopard_32
        else
          # Return, e.g., :tiger_g3, :leopard_g5_64, :leopard_64 (which is Intel)
          if Hardware::CPU.type == :ppc
            tag = "#{MacOS.cat}_#{Hardware::CPU.family}".to_sym
          else
            tag = MacOS.cat
          end
          MacOS.prefer_64_bit? ? "#{tag}_64".to_sym : tag
        end
      end
    end

    class Collector
      private

      alias original_find_matching_tag find_matching_tag
      def find_matching_tag(tag)
        original_find_matching_tag(tag) || find_altivec_tag(tag) || find_or_later_tag(tag)
      end

      # This allows generic Altivec PPC bottles to be supported in some
      # formulae, while also allowing specific bottles in others; e.g.,
      # sometimes a formula has just :tiger_altivec, other times it has
      # :tiger_g4, :tiger_g5, etc.
      def find_altivec_tag(tag)
        return unless tag.to_s =~ /(\w+)_(g4|g4e|g5)$/
        altivec_tag = "#{Regexp.last_match(1)}_altivec".to_sym
        altivec_tag if key?(altivec_tag)
      end

      # Allows a bottle tag to specify a specific OS or later,
      # so the same bottle can target multiple OSs.
      def find_or_later_tag(tag)
        begin
          tag_version = MacOS::Version.from_symbol(tag)
        rescue ArgumentError
          return
        end

        keys.find do |key|
          if key.to_s.end_with?("_or_later")
            later_tag = key.to_s[/(\w+)_or_later$/, 1].to_sym
            MacOS::Version.from_symbol(later_tag) <= tag_version
          elsif ARGV.force_bottle?
            true
          end
        end
      end
    end
  end
end
