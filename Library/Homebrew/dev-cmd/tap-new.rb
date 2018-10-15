#:  * `tap-new` <user>`/`<repo>:
#:    Generate the template files for a new tap.

require "tap"
require "cli_parser"

module Homebrew
  module_function

  def tap_new_args
    Homebrew::CLI::Parser.new do
      usage_banner <<~EOS
        `tap-new` <user>`/`<repo>

        Generate the template files for a new tap.
      EOS
      switch :verbose
      switch :debug
    end
  end

  def tap_new
    tap_new_args.parse

    raise "A tap argument is required" if ARGV.named.empty?

    tap = Tap.fetch(ARGV.named.first)
    titleized_user = tap.user.dup
    titleized_repo = tap.repo.dup
    titleized_user[0] = titleized_user[0].upcase
    titleized_repo[0] = titleized_repo[0].upcase

    (tap.path/"Formula").mkpath

    readme = <<~MARKDOWN
      # #{titleized_user} #{titleized_repo}

      ## How do I install these formulae?
      `brew install #{tap}/<formula>`

      Or `brew tap #{tap}` and then `brew install <formula>`.

      Or install via URL (which will not receive updates):

      ```
      brew install https://raw.githubusercontent.com/#{tap.user}/homebrew-#{tap.repo}/master/Formula/<formula>.rb
      ```

      ## Documentation
      `brew help`, `man brew` or check [Homebrew's documentation](https://docs.brew.sh).
    MARKDOWN
    write_path(tap, "README.md", readme)

    travis = <<~YAML
      language: c
      os: osx
      compiler: clang
      osx_image: xcode9.2
      cache:
        directories:
          - #{Homebrew::DEFAULT_PREFIX}/Homebrew/Library/Homebrew/vendor/bundle
      branches:
        only:
          - master

      before_install:
        - sudo chown -R "$USER" "$(brew --repo)"
        - travis_retry brew update
        - HOMEBREW_TAP_DIR="$(brew --repo "$TRAVIS_REPO_SLUG")"
        - mkdir -p "$HOMEBREW_TAP_DIR"
        - rm -rf "$HOMEBREW_TAP_DIR"
        - ln -s "$PWD" "$HOMEBREW_TAP_DIR"

      script:
        - brew test-bot
    YAML
    write_path(tap, ".travis.yml", travis)
  end

  def write_path(tap, filename, content)
    path = tap.path/filename
    tap.path.mkpath
    raise "#{path} already exists" if path.exist?

    path.write content
  end
end
