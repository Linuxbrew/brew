module Homebrew
  # Merge branch homebrew/master into linuxbrew/master.
  #
  # Usage:
  #    brew merge-homebrew
  #
  # Options:
  #   --brew  merge Homebrew/brew into Linuxbrew/brew
  #   --core  merge Homebrew/homebrew-core into Linuxbrew/homebrew-core
  #   --dupes merge Homebrew/homebrew-dupes into Linuxbrew/homebrew-dupes
  #
  def git_merge
    safe_system "git", "fetch", "homebrew"
    start_sha1 = Utils.popen_read("git", "rev-parse", "origin/master").chomp
    end_sha1 = Utils.popen_read("git", "rev-parse", "homebrew/master").chomp

    puts "Start commit: #{start_sha1}"
    puts "End   commit: #{end_sha1}"

    safe_system "git", "checkout", "master"
    safe_system "git", "merge", "homebrew/master", "-m", "Merge branch homebrew/master into linuxbrew/master"
  end

  def merge_brew
    oh1 "Merging Homebrew/brew into Linuxbrew/brew"
    cd(HOMEBREW_REPOSITORY) { git_merge }
  end

  def merge_core
    oh1 "Merging Homebrew/homebrew-core into Linuxbrew/homebrew-core"
    cd(CoreTap.instance.path) { git_merge }
  end

  def merge_dupes
    oh1 "Merging Homebrew/homebrew-dupes into Linuxbrew/homebrew-dupes"
    cd(Tap.fetch("linuxbrew/dupes").path) { git_merge }
  end

  def merge_homebrew
    repos = %w[--brew --core --dupes]
    args = (ARGV & repos).empty? ? repos : ARGV
    merge_brew if args.include? "--brew"
    merge_core if args.include? "--core"
    merge_dupes if args.include? "--dupes"
  end
end
