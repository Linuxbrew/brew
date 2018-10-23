class CodesignRequirement < Requirement
  fatal true

  def initialize(tags)
    options = tags.shift
    unless options.is_a?(Hash)
      raise ArgumentError("CodesignRequirement requires an options Hash!")
    end
    unless options.key?(:identity)
      raise ArgumentError("CodesignRequirement requires an identity key!")
    end

    @identity = options.fetch(:identity)
    @with = options.fetch(:with, "code signing")
    @url = options.fetch(:url, nil)
    super(tags)
  end

  satisfy(build_env: false) do
    mktemp do
      FileUtils.cp "/usr/bin/false", "codesign_check"
      quiet_system "/usr/bin/codesign", "-f", "-s", @identity,
                                        "--dryrun", "codesign_check"
    end
  end

  def message
    message = "#{@identity} identity must be available to build with #{@with}"
    message += ":\n#{@url}" if @url.present?
    message
  end
end
