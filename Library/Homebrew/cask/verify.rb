module Cask
  module Verify
    module_function

    def all(cask, downloaded_path)
      if cask.sha256 == :no_check
        ohai "No SHA-256 checksum defined for Cask '#{cask}', skipping verification."
        return
      end

      ohai "Verifying SHA-256 checksum for Cask '#{cask}'."

      expected = cask.sha256
      computed = downloaded_path.sha256

      raise CaskSha256MissingError.new(cask.token, expected, computed) if expected.nil? || expected.empty?

      return if expected == computed

      ohai "Note: Running `brew update` may fix SHA-256 checksum errors."
      raise CaskSha256MismatchError.new(cask.token, expected, computed, downloaded_path)
    end
  end
end
