require "development_tools"
module Hbc
  module Quarantine
    module_function

    QUARANTINE_ATTRIBUTE = "com.apple.quarantine".freeze

    QUARANTINE_SCRIPT = (HOMEBREW_LIBRARY_PATH/"cask/lib/hbc/utils/quarantine.swift").freeze

    # @private
    def swift
      @swift ||= DevelopmentTools.locate("swift")
    end

    def available?
      status = !swift.nil?
      odebug "Quarantine is #{status ? "available" : "not available"}."
      status
    end

    def detect(file)
      return if file.nil?

      odebug "Verifying Gatekeeper status of #{file}"

      quarantine_status = !status(file).empty?

      odebug "#{file} is #{quarantine_status ? "quarantined" : "not quarantined"}"

      quarantine_status
    end

    def status(file, command: SystemCommand)
      command.run("/usr/bin/xattr",
                  args:        ["-p", QUARANTINE_ATTRIBUTE, file],
                  print_stderr: false).stdout.rstrip
    end

    def cask(cask: nil, download_path: nil, command: SystemCommand)
      return if cask.nil? || download_path.nil?

      odebug "Quarantining #{download_path}"

      quarantiner = command.run(swift,
                                args: [
                                  QUARANTINE_SCRIPT,
                                  download_path,
                                  cask.url.to_s,
                                  cask.homepage.to_s,
                                ])

      return if quarantiner.success?

      case quarantiner.exit_status
      when 2
        raise CaskQuarantineError.new(download_path, "Insufficient parameters")
      else
        raise CaskQuarantineError.new(download_path, quarantiner.stderr)
      end
    end

    def propagate(from: nil, to: nil, command: SystemCommand)
      return if from.nil? || to.nil?

      raise CaskError, "#{from} was not quarantined properly." unless detect(from)

      odebug "Propagating quarantine from #{from} to #{to}"

      quarantine_status = status(from, command: command)

      quarantiner = command.run("/usr/bin/xattr",
                                args: ["-w", "-rs", QUARANTINE_ATTRIBUTE, quarantine_status, to],
                                print_stderr: false)

      return if quarantiner.success?

      raise CaskQuarantinePropagationError.new(to, quarantiner.stderr)
    end
  end
end
