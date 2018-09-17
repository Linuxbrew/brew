#:  * `release-notes` [`--markdown`] [<previous_tag>] [<end_ref>]:
#:    Output the merged pull requests on Homebrew/brew between two Git refs.
#:    If no <previous_tag> is provided it defaults to the latest tag.
#:    If no <end_ref> is provided it defaults to `origin/master`.
#:
#:    If `--markdown` is passed, output as a Markdown list.

require "cli_parser"

module Homebrew
  module_function

  def release_notes
    Homebrew::CLI::Parser.parse do
      switch "--markdown"
    end

    previous_tag = ARGV.named.first
    previous_tag ||= Utils.popen_read(
      "git", "-C", HOMEBREW_REPOSITORY, "tag", "--list", "--sort=-version:refname"
    ).lines.first.chomp
    odie "Could not find any previous tags!" unless previous_tag

    end_ref = ARGV.named[1] || "origin/master"

    [previous_tag, end_ref].each do |ref|
      next if quiet_system "git", "-C", HOMEBREW_REPOSITORY, "rev-parse", "--verify", "--quiet", ref

      odie "Ref #{ref} does not exist!"
    end

    output = Utils.popen_read(
      "git", "-C", HOMEBREW_REPOSITORY, "log", "--pretty=format:'%s >> - %b%n'", "#{previous_tag}..#{end_ref}"
    ).lines.grep(/Merge pull request/)

    output.map! do |s|
      s.gsub(%r{.*Merge pull request #(\d+) from ([^/]+)/[^>]*(>>)*},
             "https://github.com/Homebrew/brew/pull/\\1 (@\\2)")
    end
    if args.markdown?
      output.map! do |s|
        /(.*\d)+ \(@(.+)\) - (.*)/ =~ s
        "- [#{Regexp.last_match(3)}](#{Regexp.last_match(1)}) (@#{Regexp.last_match(2)})"
      end
    end

    puts "Release notes between #{previous_tag} and #{end_ref}:"
    puts output
  end
end
