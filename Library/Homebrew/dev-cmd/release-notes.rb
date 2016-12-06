#:  * `release-notes` [<previous_tag>] [<end_ref>]:
#:    Output the merged pull requests on Homebrew/brew between two Git refs.
#:    If no `previous_tag` is provided it defaults to the newest tag.
#:    If no `end_ref` is provided it defaults to `origin/master`.
#:
#:    If `--markdown` is passed, output as a Markdown list.

module Homebrew
  module_function

  def release_notes
    previous_tag = ARGV.named.first
    unless previous_tag
      previous_tag = Utils.popen_read("git tag --list --sort=-version:refname")
                          .lines.first.chomp
    end
    odie "Could not find any previous tags!" unless previous_tag

    end_ref = ARGV.named[1] || "origin/master"

    [previous_tag, end_ref].each do |ref|
      next if quiet_system "git", "rev-parse", "--verify", "--quiet", ref
      odie "Ref #{ref} does not exist!"
    end

    output = Utils.popen_read("git log --pretty=format:'%s >> - %b%n' '#{previous_tag}'..'#{end_ref}'")
                  .lines.grep(/Merge pull request/)

    output.map! do |s|
      s.gsub(/.*Merge pull request #(\d+)[^>]*(>>)*/,
             "https://github.com/Homebrew/brew/pull/\\1")
    end
    if ARGV.include?("--markdown")
      output.map! do |s|
        /(.*\d)+ - (.*)/ =~ s
        "- [#{$2}](#{$1})"
      end
    end

    puts "Release notes between #{previous_tag} and #{end_ref}:"
    puts output
  end
end
