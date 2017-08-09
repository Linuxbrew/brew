require "digest"

module Hbc
  module Verify
    class Checksum
      def self.me?(cask)
        return true unless cask.sha256 == :no_check
        ohai "No checksum defined for Cask #{cask}, skipping verification"
        false
      end

      attr_reader :cask, :downloaded_path

      def initialize(cask, downloaded_path)
        @cask = cask
        @downloaded_path = downloaded_path
      end

      def verify
        return unless self.class.me?(cask)
        ohai "Verifying checksum for Cask #{cask}"
        verify_checksum
      end

      private

      def expected
        @expected ||= cask.sha256
      end

      def computed
        @computed ||= Digest::SHA2.file(downloaded_path).hexdigest
      end

      def verify_checksum
        raise CaskSha256MissingError.new(cask.token, expected, computed) if expected.nil? || expected.empty?

        if expected == computed
          odebug "SHA256 checksums match"
        else
          ohai 'Note: running "brew update" may fix sha256 checksum errors'
          raise CaskSha256MismatchError.new(cask.token, expected, computed, downloaded_path)
        end
      end
    end
  end
end
