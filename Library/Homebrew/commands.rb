module Commands
  def self.path(cmd)
    if File.exist?(HOMEBREW_LIBRARY_PATH/"cmd/#{cmd}.sh")
      HOMEBREW_LIBRARY_PATH/"cmd/#{cmd}.sh"
    elsif File.exist?(HOMEBREW_LIBRARY_PATH/"dev-cmd/#{cmd}.sh")
      HOMEBREW_LIBRARY_PATH/"dev-cmd/#{cmd}.sh"
    elsif File.exist?(HOMEBREW_LIBRARY_PATH/"cmd/#{cmd}.rb")
      HOMEBREW_LIBRARY_PATH/"cmd/#{cmd}.rb"
    elsif File.exist?(HOMEBREW_LIBRARY_PATH/"dev-cmd/#{cmd}.rb")
      HOMEBREW_LIBRARY_PATH/"dev-cmd/#{cmd}.rb"
    end
  end
end
