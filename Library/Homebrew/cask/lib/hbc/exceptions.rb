module Hbc
  class CaskError < RuntimeError; end

  class AbstractCaskErrorWithToken < CaskError
    attr_reader :token

    def initialize(token)
      @token = token
    end
  end

  class CaskNotInstalledError < AbstractCaskErrorWithToken
    def to_s
      "#{token} is not installed"
    end
  end

  class CaskUnavailableError < AbstractCaskErrorWithToken
    def to_s
      "No available Cask for #{token}"
    end
  end

  class CaskAlreadyCreatedError < AbstractCaskErrorWithToken
    def to_s
      %Q(A Cask for #{token} already exists. Run "brew cask cat #{token}" to see it.)
    end
  end

  class CaskAlreadyInstalledError < AbstractCaskErrorWithToken
    def to_s
      s = <<-EOS.undent
        A Cask for #{token} is already installed.
      EOS

      s.concat("\n").concat(reinstall_message)
    end

    private

    def reinstall_message
      <<-EOS.undent
        To re-install #{token}, run:
          brew cask reinstall #{token}
      EOS
    end
  end

  class CaskAlreadyInstalledAutoUpdatesError < CaskAlreadyInstalledError
    def to_s
      s = <<-EOS.undent
        A Cask for #{token} is already installed and using auto-updates.
      EOS

      s.concat("\n").concat(reinstall_message)
    end
  end

  class CaskCommandFailedError < CaskError
    def initialize(cmd, stdout, stderr, status)
      @cmd = cmd
      @stdout = stdout
      @stderr = stderr
      @status = status
    end

    def to_s
      s = "Command failed to execute!\n"
      s.concat("\n")
      s.concat("==> Failed command:\n")
      s.concat(@cmd.join(" ")).concat("\n")
      s.concat("\n")
      s.concat("==> Standard Output of failed command:\n")
      s.concat(@stdout).concat("\n")
      s.concat("\n")
      s.concat("==> Standard Error of failed command:\n")
      s.concat(@stderr).concat("\n")
      s.concat("\n")
      s.concat("==> Exit status of failed command:\n")
      s.concat(@status.inspect).concat("\n")
    end
  end

  class CaskX11DependencyError < AbstractCaskErrorWithToken
    def to_s
      <<-EOS.undent
        #{token} requires XQuartz/X11, which can be installed using Homebrew-Cask by running
          brew cask install xquartz

        or manually, by downloading the package from
          #{Formatter.url("https://www.xquartz.org/")}
      EOS
    end
  end

  class CaskCyclicCaskDependencyError < AbstractCaskErrorWithToken
    def to_s
      "Cask '#{token}' includes cyclic dependencies on other Casks and could not be installed."
    end
  end

  class CaskUnspecifiedError < CaskError
    def to_s
      "This command requires a Cask token"
    end
  end

  class CaskInvalidError < AbstractCaskErrorWithToken
    attr_reader :submsg
    def initialize(token, *submsg)
      super(token)
      @submsg = submsg.join(" ")
    end

    def to_s
      "Cask '#{token}' definition is invalid" + (!submsg.empty? ? ": #{submsg}" : "")
    end
  end

  class CaskTokenDoesNotMatchError < CaskInvalidError
    def initialize(token, header_token)
      super(token, "Bad header line: '#{header_token}' does not match file name")
    end
  end

  class CaskSha256MissingError < ArgumentError
  end

  class CaskSha256MismatchError < RuntimeError
    attr_reader :path, :expected, :actual
    def initialize(path, expected, actual)
      @path = path
      @expected = expected
      @actual = actual
    end

    def to_s
      <<-EOS.undent
        sha256 mismatch
        Expected: #{expected}
        Actual: #{actual}
        File: #{path}
        To retry an incomplete download, remove the file above.
      EOS
    end
  end

  class CaskNoShasumError < CaskError
    attr_reader :token
    def initialize(token)
      @token = token
    end

    def to_s
      <<-EOS.undent
        Cask '#{token}' does not have a sha256 checksum defined and was not installed.
        This means you have the "--require-sha" option set, perhaps in your HOMEBREW_CASK_OPTS.
      EOS
    end
  end
end
