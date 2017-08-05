require "hbc/dsl"
require "hbc/metadata"

module Hbc
  class Cask
    extend Forwardable
    include Metadata

    attr_reader :token, :sourcefile_path

    def tap
      return super if block_given? # Object#tap
      @tap
    end

    def initialize(token, sourcefile_path: nil, tap: nil, &block)
      @token = token
      @sourcefile_path = sourcefile_path
      @tap = tap
      @dsl = DSL.new(@token)
      return unless block_given?
      @dsl.instance_eval(&block)
      @dsl.language_eval
    end

    DSL::DSL_METHODS.each do |method_name|
      define_method(method_name) { @dsl.send(method_name) }
    end

    def timestamped_versions
      Pathname.glob(metadata_timestamped_path(version: "*", timestamp: "*"))
              .map { |p| p.relative_path_from(p.parent.parent) }
              .sort_by(&:basename) # sort by timestamp
              .map { |p| p.split.map(&:to_s) }
    end

    def versions
      timestamped_versions.map(&:first)
                          .reverse
                          .uniq
                          .reverse
    end

    def installed?
      !versions.empty?
    end

    def installed_caskfile
      installed_version = timestamped_versions.last
      metadata_master_container_path.join(*installed_version, "Casks", "#{token}.rb")
    end

    def outdated?(greedy = false)
      !outdated_versions(greedy).empty?
    end

    def outdated_versions(greedy = false)
      # special case: tap version is not available
      return [] if version.nil?

      if greedy
        return versions if version.latest?
      elsif auto_updates
        return []
      end

      installed = versions
      current   = installed.last

      # not outdated unless there is a different version on tap
      return [] if current == version

      # collect all installed versions that are different than tap version and return them
      installed.reject { |v| v == version }
    end

    def to_s
      @token
    end

    def hash
      token.hash
    end

    def eql?(other)
      token == other.token
    end
    alias == eql?

    def dumpcask
      odebug "Cask instance dumps in YAML:"
      odebug "Cask instance toplevel:", to_yaml
      [
        :name,
        :homepage,
        :url,
        :appcast,
        :version,
        :sha256,
        :artifacts,
        :caveats,
        :depends_on,
        :conflicts_with,
        :container,
        :gpg,
        :accessibility_access,
        :auto_updates,
      ].each do |method|
        odebug "Cask instance method '#{method}':", send(method).to_yaml
      end
    end
  end
end
