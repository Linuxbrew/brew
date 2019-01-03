#:  * `vendor-gems`:
#:    Install and commit Homebrew's vendored gems.

require "formula"
require "cli_parser"

module Homebrew
  module_function

  def vendor_gems
    Homebrew::CLI::Parser.new do
      usage_banner <<~EOS
        `vendor-gems`

        Install and commit Homebrew's vendored gems.
      EOS
      switch :debug
    end.parse

    Homebrew.install_gem_setup_path! "bundler", "<2"

    ohai "cd #{HOMEBREW_LIBRARY_PATH}/vendor"
    (HOMEBREW_LIBRARY_PATH/"vendor").cd do
      ohai "bundle install --standalone"
      safe_system "bundle", "install", "--standalone"

      ohai "git add bundle-standalone"
      system "git", "add", "bundle-standalone"

      if Formula["gpg"].installed?
        ENV["PATH"] = PATH.new(ENV["PATH"])
                          .prepend(Formula["gpg"].opt_bin)
      end

      ohai "git commit"
      system "git", "commit", "--message", "brew vendor-gems: commit updates."
    end
  end
end
