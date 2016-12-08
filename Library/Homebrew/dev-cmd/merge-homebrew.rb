# Merge branch homebrew/master into linuxbrew/master.
#
# Usage:
#    brew merge-homebrew
#
# Options:
#   --brew  merge Homebrew/brew into Linuxbrew/brew
#   --core  merge Homebrew/homebrew-core into Linuxbrew/homebrew-core
#   --dupes merge Homebrew/homebrew-dupes into Linuxbrew/homebrew-dupes
#   --science merge Homebrew/homebrew-science into Linuxbrew/homebrew-science

require "date"

module Homebrew
  def editor
    return @editor if @editor
    @editor = [which_editor]
    @editor += ["-f", "+/^<<<<"] if editor[0] == "gvim"
  end

  def git
    @git ||= Utils.git_path
  end

  def git_merge(fast_forward: false)
    remotes = Utils.popen_read(git, "remote").split
    odie "Please add a remote with the name 'homebrew' in #{Dir.pwd}" unless remotes.include? "homebrew"
    odie "Please add a remote with the name 'origin' in #{Dir.pwd}" unless remotes.include? "origin"

    safe_system git, "pull", "--ff-only", "origin"
    safe_system git, "fetch", "homebrew"
    start_sha1 = Utils.popen_read(git, "rev-parse", "origin/master").chomp
    end_sha1 = Utils.popen_read(git, "rev-parse", "homebrew/master").chomp

    puts "Start commit: #{start_sha1}"
    puts "End   commit: #{end_sha1}"

    safe_system git, "checkout", "master"
    args = []
    args << "--ff-only" if fast_forward
    system git, "merge", *args, "homebrew/master", "-m", "Merge branch homebrew/master into linuxbrew/master"
  end

  def resolve_conflicts
    conflicts = Utils.popen_read(git, "diff", "--name-only", "--diff-filter=U").split
    return conflicts if conflicts.empty?
    oh1 "Conflicts"
    puts conflicts.join(" ")
    safe_system *editor, *conflicts
    safe_system HOMEBREW_BREW_FILE, "style", *conflicts
    safe_system git, "diff", "--check"
    safe_system git, "add", "--", *conflicts
    conflicts
  end

  def merge_brew
    oh1 "Merging Homebrew/brew into Linuxbrew/brew"
    cd(HOMEBREW_REPOSITORY) { git_merge }
  end

  def merge_core
    oh1 "Merging Homebrew/homebrew-core into Linuxbrew/homebrew-core"
    cd(CoreTap.instance.path) do
      git_merge
      conflict_files = resolve_conflicts
      next if conflict_files.empty?
      safe_system git, "commit"
      conflict_files = "Formula/closure-compiler.rb Formula/crystal-lang.rb Formula/ffmpeg.rb Formula/git-lfs.rb Formula/harfbuzz.rb Formula/imagemagick.rb Formula/jasper.rb Formula/jemalloc.rb Formula/libcue.rb Formula/neofetch.rb Formula/node.rb Formula/shared-mime-info.rb Formula/td.rb Formula/vala.rb Formula/vim.rb".split
      conflicts = conflict_files.map { |s| s.gsub(%r{^Formula/|\.rb$}, "") }
      message =
        "Update bottles for merge #{Date.today}\n\n" +
        conflicts.map { |s| "+ [ ] #{s}\n" }.join
      Tempfile.open("merge-homebrew-message", HOMEBREW_TEMP) do |f|
        f.write message
        f.close
        safe_system "hub", "issue", "create", "-l", "merge", "-f", f.path
      end
      puts "Now run:\n  git push origin\n  brew build-bottle-pr #{conflicts.join(" ")}"
    end
  end

  def merge_dupes
    oh1 "Merging Homebrew/homebrew-dupes into Linuxbrew/homebrew-dupes"
    cd(Tap.fetch("homebrew/dupes").path) { git_merge }
  end

  def merge_science
    oh1 "Merging Homebrew/homebrew-science into Linuxbrew/homebrew-science"
    cd Tap.fetch("homebrew/science").path

    safe_system git, "fetch", "homebrew"
    safe_system git, "pull", "--ff-only", "origin"
    files = Utils.popen_read(git, "diff", "--name-only", "homebrew/master").split
    return if files.empty?

    puts "Updated upstream: #{files.join(" ")}"
    files.select! do |filename|
      next true unless File.readable? filename
      !File.read(filename)[/bottle :(disabled|unneeded)/]
    end
    unless files.empty?
      log = Utils.popen_read(git, "log", "origin/master..homebrew/master", "--", *files)
      issues = log.scan(/^    Closes #([0-9]*)\.$/).flatten.reverse
    end
    if issues.nil? || issues.empty?
      git_merge fast_forward: true
      oh1 "No bottles to update"
      puts "Now run:\n  git push homebrew && git push origin"
      return
    end

    urls = issues.map { |n| "https://github.com/Homebrew/homebrew-science/pull/#{n}" }
    puts "Updating bottles: #{files.join(" ")}", "Pull requests: #{issues.join(" ")}", urls
    urls.each do |url|
      system HOMEBREW_BREW_FILE, "pull", "--bottle", "--resolve", url
      while Utils.popen_read(git, "status").include? "You are in the middle of an am session."
        conflicts = resolve_conflicts
        if conflicts.empty?
          opoo "Skipping empty patch"
          safe_system git, "am", "--skip"
          next
        end
        system git, "am", "--continue"
      end
      safe_system git, "checkout", "-B", "master"
    end

    system git, "rebase", "homebrew/master"
    until (conflicts = Utils.popen_read(git, "diff", "--name-only", "--diff-filter=U").split).empty?
      oh1 "Conflicts: #{conflicts.join(" ")}"
      safe_system *editor, *conflicts
      safe_system git, "add", *conflicts
      system git, "rebase", "--continue"
    end

    safe_system git, "log", "--oneline", "--decorate=short", "homebrew/master..master"
    safe_system git, "diff", "homebrew/master..master"
    oh1 "Done"
    puts "Now run:\n  git push homebrew && git push origin"
  end

  def merge_homebrew
    Utils.ensure_git_installed!
    repos = %w[--brew --core --dupes --science]
    args = (ARGV & repos).empty? ? repos : ARGV
    merge_brew if args.include? "--brew"
    merge_core if args.include? "--core"
    merge_dupes if args.include? "--dupes"
    merge_science if args.include? "--science"
  end
end
