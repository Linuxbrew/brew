module Homebrew
  # Merge branch homebrew/master into linuxbrew/master.
  #
  # Usage:
  #    brew merge-homebrew
  #
  # Options:
  #   --brew  merge Homebrew/brew into Linuxbrew/brew
  #   --core  merge Homebrew/homebrew-core into Linuxbrew/homebrew-core
  #
  def git_merge
    safe_system *%w[git fetch homebrew]
    start_sha1 = Utils.popen_read("git", "rev-parse", "origin/master").chomp
    end_sha1 = Utils.popen_read("git", "rev-parse", "homebrew/master").chomp

    puts "Start commit: #{start_sha1}"
    puts "End   commit: #{end_sha1}"

    safe_system *%w[git checkout master]
    safe_system *%w[git merge homebrew/master -m], "Merge branch homebrew/master into linuxbrew/master"
  end

  def merge_brew
    oh1 "Merging Homebrew/brew into Linuxbrew/brew"
    cd(HOMEBREW_REPOSITORY) { git_merge }
  end

  def merge_core
    oh1 "Merging Homebrew/homebrew-core into Linuxbrew/homebrew-core"
    cd(CoreTap.instance.path) { git_merge }
  end

  def merge_homebrew
    ARGV << "--brew" << "--core" unless ARGV.include?("--brew") || ARGV.include?("--core")
    merge_brew if ARGV.include? "--brew"
    merge_core if ARGV.include? "--core"
  end
end
