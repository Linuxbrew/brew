require "cask/cask_loader"
require "cask/config"
require "cask/dsl"
require "cask/metadata"
require "searchable"

module Cask
  class Cask
    extend Enumerable
    extend Forwardable
    extend Searchable
    include Metadata

    attr_reader :token, :sourcefile_path, :config

    def self.each
      return to_enum unless block_given?

      Tap.flat_map(&:cask_files).each do |f|
        begin
          yield CaskLoader::FromTapPathLoader.new(f).load
        rescue CaskUnreadableError => e
          opoo e.message
        end
      end
    end

    def tap
      return super if block_given? # Object#tap

      @tap
    end

    def initialize(token, sourcefile_path: nil, tap: nil, config: Config.global, &block)
      @token = token
      @sourcefile_path = sourcefile_path
      @tap = tap
      @config = config
      @dsl = DSL.new(self)
      return unless block_given?

      @dsl.instance_eval(&block)
      @dsl.language_eval
    end

    DSL::DSL_METHODS.each do |method_name|
      define_method(method_name) { |&block| @dsl.send(method_name, &block) }
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

    def full_name
      return token if tap.nil?
      return token if tap.user == "Homebrew"

      "#{tap.name}/#{token}"
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

    def to_h
      {
        "name"           => name,
        "homepage"       => homepage,
        "url"            => url,
        "appcast"        => appcast,
        "version"        => version,
        "sha256"         => sha256,
        "artifacts"      => artifacts.map do |a|
          if a.respond_to? :to_h
            a.to_h
          elsif a.respond_to? :to_a
            a.to_a
          else
            a
          end
        end,
        "caveats"        => caveats,
        "depends_on"     => depends_on,
        "conflicts_with" => conflicts_with.to_a,
        "container"      => container,
        "auto_updates"   => auto_updates,
      }
    end
  end
end
