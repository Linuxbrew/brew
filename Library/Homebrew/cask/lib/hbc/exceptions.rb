module Hbc
  class CaskError < RuntimeError; end

  class AbstractCaskErrorWithToken < CaskError
    attr_reader :token
    attr_reader :reason

    def initialize(token, reason = nil)
      @token = token
      @reason = reason.to_s
    end
  end

  class CaskNotInstalledError < AbstractCaskErrorWithToken
    def to_s
      "Cask '#{token}' is not installed."
    end
  end

  class CaskConflictError < AbstractCaskErrorWithToken
    attr_reader :conflicting_cask

    def initialize(token, conflicting_cask)
      super(token)
      @conflicting_cask = conflicting_cask
    end

    def to_s
      "Cask '#{token}' conflicts with '#{conflicting_cask}'."
    end
  end

  class CaskUnavailableError < AbstractCaskErrorWithToken
    def to_s
      "Cask '#{token}' is unavailable" << (reason.empty? ? "." : ": #{reason}")
    end
  end

  class CaskAlreadyCreatedError < AbstractCaskErrorWithToken
    def to_s
      %Q(Cask '#{token}' already exists. Run #{Formatter.identifier("brew cask cat #{token}")} to edit it.)
    end
  end

  class CaskAlreadyInstalledError < AbstractCaskErrorWithToken
    def to_s
      <<-EOS.undent
        Cask '#{token}' is already installed.

        To re-install #{token}, run:
          #{Formatter.identifier("brew cask reinstall #{token}")}
      EOS
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
        Cask '#{token}' requires XQuartz/X11, which can be installed using Homebrew-Cask by running
          #{Formatter.identifier("brew cask install xquartz")}

        or manually, by downloading the package from
          #{Formatter.url("https://www.xquartz.org/")}
      EOS
    end
  end

  class CaskCyclicDependencyError < AbstractCaskErrorWithToken
    def to_s
      "Cask '#{token}' includes cyclic dependencies on other Casks" << (reason.empty? ? "." : ": #{reason}")
    end
  end

  class CaskSelfReferencingDependencyError < CaskCyclicDependencyError
    def to_s
      "Cask '#{token}' depends on itself."
    end
  end

  class CaskUnspecifiedError < CaskError
    def to_s
      "This command requires a Cask token."
    end
  end

  class CaskInvalidError < AbstractCaskErrorWithToken
    def to_s
      "Cask '#{token}' definition is invalid" << (reason.empty? ? "." : ": #{reason}")
    end
  end

  class CaskTokenMismatchError < CaskInvalidError
    def initialize(token, header_token)
      super(token, "Token '#{header_token}' in header line does not match the file name.")
    end
  end

  class CaskSha256Error < AbstractCaskErrorWithToken
    attr_reader :expected, :actual

    def initialize(token, expected = nil, actual = nil)
      super(token)
      @expected = expected
      @actual = actual
    end
  end

  class CaskSha256MissingError < CaskSha256Error
    def to_s
      <<-EOS.undent
        Cask '#{token}' requires a checksum:
          #{Formatter.identifier("sha256 '#{actual}'")}
      EOS
    end
  end

  class CaskSha256MismatchError < CaskSha256Error
    attr_reader :path

    def initialize(token, expected, actual, path)
      super(token, expected, actual)
      @path = path
    end

    def to_s
      <<-EOS.undent
        Checksum for Cask '#{token}' does not match.

        Expected: #{Formatter.success(expected.to_s)}
        Actual:   #{Formatter.error(actual.to_s)}
        File:     #{path}

        To retry an incomplete download, remove the file above.
      EOS
    end
  end

  class CaskNoShasumError < CaskSha256Error
    def to_s
      <<-EOS.undent
        Cask '#{token}' does not have a sha256 checksum defined and was not installed.
        This means you have the #{Formatter.identifier("--require-sha")} option set, perhaps in your HOMEBREW_CASK_OPTS.
      EOS
    end
  end
end
