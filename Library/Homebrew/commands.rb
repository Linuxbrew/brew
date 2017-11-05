module Commands
  def self.path(cmd)
    [
      HOMEBREW_LIBRARY_PATH/"cmd/#{cmd}.sh",
      HOMEBREW_LIBRARY_PATH/"dev-cmd/#{cmd}.sh",
      HOMEBREW_LIBRARY_PATH/"cmd/#{cmd}.rb",
      HOMEBREW_LIBRARY_PATH/"dev-cmd/#{cmd}.rb",
    ].find(&:exist?)
  end
end
