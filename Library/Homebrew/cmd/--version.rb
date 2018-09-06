#:  * `--version`:
#:    Print the version number of Homebrew to standard output and exit.

module Homebrew
  module_function

  def __version
    odie "This command does not take arguments." if ARGV.any?

    puts "Homebrew #{HOMEBREW_VERSION}"
    puts "#{CoreTap.instance.full_name} #{CoreTap.instance.version_string}"
    puts "#{Tap.default_cask_tap.full_name} #{Tap.default_cask_tap.version_string}" if Tap.default_cask_tap.installed?
  end
end
