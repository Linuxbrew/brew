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
      `brew help`, `man brew` or check [Homebrew's documentation](https://github.com/Homebrew/brew/tree/master/docs#readme).
    EOS
    write_path(tap, "README.md", readme)

    travis = <<-EOS.undent
    language: ruby
    os: osx
    env: OSX=10.11
    osx_image: xcode7.3
    rvm: system

    before_install:
      - export TRAVIS_COMMIT="$(git rev-parse --verify -q HEAD)"
      - if [ -f ".git/shallow" ]; then
          travis_retry git fetch --unshallow;
        fi
      - sudo chown -R $USER "$(brew --repo)"
      - git -C "$(brew --repo)" reset --hard origin/master
      - git -C "$(brew --repo)" clean -qxdff
      - brew update || brew update
      - rm -rf "$(brew --repo $TRAVIS_REPO_SLUG)"
      - mkdir -p "$(brew --repo $TRAVIS_REPO_SLUG)"
      - rsync -az "$TRAVIS_BUILD_DIR/" "$(brew --repo $TRAVIS_REPO_SLUG)"
      - export TRAVIS_BUILD_DIR="$(brew --repo $TRAVIS_REPO_SLUG)"
      - cd "$(brew --repo)"
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
