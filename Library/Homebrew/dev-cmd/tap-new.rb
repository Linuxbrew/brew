#:  * `tap-new` <user>`/`<repo>:
#:    Generate the template files for a new tap.

require "tap"

module Homebrew
  module_function

  def write_path(tap, filename, content)
    path = tap.path/filename
    tap.path.mkpath
    raise "#{path} already exists" if path.exist?
    path.write content
  end

  def tap_new
    raise "A tap argument is required" if ARGV.named.empty?

    tap = Tap.fetch(ARGV.named.first)
    titleized_user = tap.user.dup
    titleized_repo = tap.repo.dup
    titleized_user[0] = titleized_user[0].upcase
    titleized_repo[0] = titleized_repo[0].upcase

    (tap.path/"Formula").mkpath

    readme = <<-EOS.undent
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
    EOS
    write_path(tap, "README.md", readme)

    travis = <<-EOS.undent
      language: ruby
      os: osx
      env: OSX=10.12
      osx_image: xcode8.3
      rvm: system
      cache:
        directories:
          - $HOME/.gem/ruby
          - Library/Homebrew/vendor/bundle

      before_install:
        - export TRAVIS_COMMIT="$(git rev-parse --verify -q HEAD)"
        - if [ -f ".git/shallow" ]; then
            travis_retry git fetch --unshallow;
          fi
        - HOMEBREW_REPOSITORY="$(brew --repo)"
        - sudo chown -R "$USER" "$HOMEBREW_REPOSITORY"
        - git -C "$HOMEBREW_REPOSITORY" reset --hard origin/master
        - brew update || brew update
        - HOMEBREW_TAP_DIR="$(brew --repo "$TRAVIS_REPO_SLUG")"
        - mkdir -p "$HOMEBREW_TAP_DIR"
        - rm -rf "$HOMEBREW_TAP_DIR"
        - ln -s "$PWD" "$HOMEBREW_TAP_DIR"
        - export HOMEBREW_DEVELOPER="1"
        - ulimit -n 1024

      script:
        - brew test-bot

      notifications:
        email:
          on_success: never
          on_failure: always
    EOS
    write_path(tap, ".travis.yml", travis)
  end
end
