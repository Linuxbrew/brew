require "formulary"
require "tap"
require "utils"

module Homebrew
  module MissingFormula
    class << self
      def reason(name, silent: false)
        blacklisted_reason(name) || tap_migration_reason(name) ||
          deleted_reason(name, silent: silent)
      end

      def blacklisted_reason(name)
        case name.downcase
        when "gem", /^rubygems?$/ then <<-EOS.undent
          Homebrew provides gem via: `brew install ruby`.
          EOS
        when "tex", "tex-live", "texlive", "latex" then <<-EOS.undent
          Installing TeX from source is weird and gross, requires a lot of patches,
          and only builds 32-bit (and thus can't use Homebrew dependencies)

          We recommend using a MacTeX distribution: https://www.tug.org/mactex/

          You can install it with Homebrew-Cask:
            brew cask install mactex
          EOS
        when "pip" then <<-EOS.undent
          Homebrew provides pip via: `brew install python`. However you will then
          have two Pythons installed on your Mac, so alternatively you can install
          pip via the instructions at:
            #{Formatter.url("https://pip.readthedocs.io/en/stable/installing/")}
          EOS
        when "pil" then <<-EOS.undent
          Instead of PIL, consider `pip2 install pillow`.
          EOS
        when "macruby" then <<-EOS.undent
          MacRuby is not packaged and is on an indefinite development hiatus.
          You can read more about it at:
            #{Formatter.url("https://github.com/MacRuby/MacRuby")}
          EOS
        when /(lib)?lzma/
          "lzma is now part of the xz formula."
        when "gtest", "googletest", "google-test" then <<-EOS.undent
          Installing gtest system-wide is not recommended; it should be vendored
          in your projects that use it.
          EOS
        when "gmock", "googlemock", "google-mock" then <<-EOS.undent
          Installing gmock system-wide is not recommended; it should be vendored
          in your projects that use it.
          EOS
        when "sshpass" then <<-EOS.undent
          We won't add sshpass because it makes it too easy for novice SSH users to
          ruin SSH's security.
          EOS
        when "gsutil" then <<-EOS.undent
          Install gsutil with `pip2 install gsutil`
          EOS
        when "gfortran" then <<-EOS.undent
          GNU Fortran is now provided as part of GCC, and can be installed with:
            brew install gcc
          EOS
        when "play" then <<-EOS.undent
          Play 2.3 replaces the play command with activator:
            brew install typesafe-activator

          You can read more about this change at:
            #{Formatter.url("https://www.playframework.com/documentation/2.3.x/Migration23")}
            #{Formatter.url("https://www.playframework.com/documentation/2.3.x/Highlights23")}
          EOS
        when "haskell-platform" then <<-EOS.undent
          We no longer package haskell-platform. Consider installing ghc
          and cabal-install instead:
            brew install ghc cabal-install

          You can install with Homebrew-Cask:
            brew cask install haskell-platform
          EOS
        when "mysqldump-secure" then <<-EOS.undent
          The creator of mysqldump-secure tried to game our popularity metrics.
          EOS
        when "ngrok" then <<-EOS.undent
          Upstream sunsetted 1.x in March 2016 and 2.x is not open-source.

          If you wish to use the 2.x release you can install with Homebrew-Cask:
            brew cask install ngrok
          EOS
        end
      end
      alias generic_blacklisted_reason blacklisted_reason

      def tap_migration_reason(name)
        message = nil

        Tap.each do |old_tap|
          new_tap = old_tap.tap_migrations[name]
          next unless new_tap

          new_tap_user, new_tap_repo, = new_tap.split("/")
          new_tap_name = "#{new_tap_user}/#{new_tap_repo}"

          message = <<-EOS.undent
            It was migrated from #{old_tap} to #{new_tap}.
          EOS
          break if new_tap_name == CoreTap.instance.name

          message += <<-EOS.undent
            You can access it again by running:
              brew tap #{new_tap_name}
          EOS
          break
        end

        message
      end

      def deleted_reason(name, silent: false)
        path = Formulary.path name
        return if File.exist? path
        tap = Tap.from_path(path)
        return if tap.nil? || !File.exist?(tap.path)
        relative_path = path.relative_path_from tap.path

        tap.path.cd do
          unless silent
            ohai "Searching for a previously deleted formula..."
            if (tap.path/".git/shallow").exist?
              opoo <<-EOS.undent
                #{tap} is shallow clone. To get complete history run:
                  git -C "$(brew --repo #{tap})" fetch --unshallow

              EOS
            end
          end

          log_command = "git log --name-only --max-count=1 --format=%H\\\\n%h\\\\n%B -- #{relative_path}"
          hash, short_hash, *commit_message, relative_path =
            Utils.popen_read(log_command).gsub("\\n", "\n").lines.map(&:chomp)

          if hash.to_s.empty? || short_hash.to_s.empty? ||
             relative_path.to_s.empty?
            ofail "No previously deleted formula found." unless silent
            return
          end

          commit_message = commit_message.reject(&:empty?).join("\n  ")

          commit_message.sub!(/ \(#(\d+)\)$/, " (#{tap.issues_url}/\\1)")
          commit_message.gsub!(/(Closes|Fixes) #(\d+)/, "\\1 #{tap.issues_url}/\\2")

          <<-EOS.undent
            #{name} was deleted from #{tap.name} in commit #{short_hash}:
              #{commit_message}

            To show the formula before removal run:
              git -C "$(brew --repo #{tap})" show #{short_hash}^:#{relative_path}

            If you still use this formula consider creating your own tap:
              https://docs.brew.sh/How-to-Create-and-Maintain-a-Tap.html
          EOS
        end
      end

      require "extend/os/missing_formula"
    end
  end
end
