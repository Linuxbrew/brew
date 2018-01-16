require "dbm"
require "json"

#
# `DatabaseCache` is a class acting as an interface to a persistent storage
# mechanism residing in the `HOMEBREW_CACHE`
#
class DatabaseCache
  # Name of the database cache file located at <HOMEBREW_CACHE>/<name>.db
  #
  # @return [String]
  attr_accessor :name

  # Instantiates new `DatabaseCache` object
  #
  # @param  [String] name
  # @return [nil]
  def initialize(name)
    @name = name
  end

  # Memoized `DBM` database object with on-disk database located in the
  # `HOMEBREW_CACHE`
  #
  # @return [DBM] db
  def db
    @db ||= DBM.open("#{HOMEBREW_CACHE}/#{name}", 0666, DBM::WRCREAT)
  end

  # Close the `DBM` database object after usage
  #
  # @return [nil]
  def close
    db.close
  end
end

#
# `CacheStore` is an abstract base class which provides methods to mutate and
# fetch data from a persistent storage mechanism
#
# @abstract
#
class CacheStore
  # Instantiates a new `CacheStore` class
  #
  # @param  [DatabaseCache] database_cache
  # @return [nil]
  def initialize(database_cache)
    @db = database_cache.db
  end

  # Inserts new values or updates existing cached values to persistent storage
  # mechanism
  #
  # @abstract
  # @param  [Any]
  # @return [nil]
  def update!(*)
    raise NotImplementedError
  end

  # Fetches cached values in persistent storage according to the type of data
  # stored
  #
  # @abstract
  # @param  [Any]
  # @return [Any]
  def fetch(*)
    raise NotImplementedError
  end

  # Deletes data from the cache based on a condition defined in a concrete class
  #
  # @abstract
  # @return [nil]
  def flush_cache!
    raise NotImplementedError
  end

  protected

  # A class instance providing access to the `DBM` database object
  #
  # @return [DBM]
  attr_reader :db
end

#
# `LinkageStore` is a concrete class providing methods to fetch and mutate
# linkage-specific data used by the `brew linkage` command
#
# If the cache hasn't changed, don't do extra processing in `LinkageChecker`.
# Instead, just fetch the data stored in the cache
#
class LinkageStore < CacheStore
  # Types of dylibs of the form (label -> array)
  HASH_LINKAGE_TYPES = %w[brewed_dylibs reverse_links].freeze

  # The keg name for the `LinkageChecker` class
  #
  # @return [String]
  attr_reader :key

  # Initializes new `LinkageStore` class
  #
  # @param  [String]        keg_name
  # @param  [DatabaseCache] database_cache
  # @return [nil]
  def initialize(keg_name, database_cache)
    @key = keg_name
    super(database_cache)
  end

  # Inserts new values or updates existing cached values to persistent storage
  # mechanism according to the type of data
  #
  # @param  [Hash] path_values
  # @param  [Hash] hash_values
  # @return [nil]
  def update!(
    path_values: {
      "system_dylibs" => %w[], "variable_dylibs" => %w[], "broken_dylibs" => %w[],
      "indirect_deps" => %w[], "undeclared_deps" => %w[], "unnecessary_deps" => %w[]
    },
    hash_values: {
      "brewed_dylibs" => {}, "reverse_links" => {}
    }
  )
    db[key] = {
      "path_values" => format_path_values(path_values),
      "hash_values" => format_hash_values(hash_values),
    }
  end

  # Fetches cached values in persistent storage according to the type of data
  # stored
  #
  # @param  [String] type
  # @return [Any]
  def fetch(type:)
    if HASH_LINKAGE_TYPES.include?(type)
      fetch_hash_values(type: type)
    else
      fetch_path_values(type: type)
    end
  end

  # A condition for where to flush the cache
  #
  # @return [String]
  def flush_cache!
    db.delete(key)
  end

  private

  # Fetches a subset of paths where the name = `key`
  #
  # @param  [String] type
  # @return [Array[String]]
  def fetch_path_values(type:)
    return [] unless db.key?(key) && !db[key].nil?
    string_to_hash(db[key])["path_values"][type]
  end

  # Fetches a subset of paths and labels where the name = `key`. Formats said
  # paths/labels into `key => [value]` syntax expected by `LinkageChecker`
  #
  # @param  [String] type
  # @return [Hash]
  def fetch_hash_values(type:)
    return {} unless db.key?(key) && !db[key].nil?
    string_to_hash(db[key])["hash_values"][type]
  end

  # Parses `DBM` stored `String` into ruby `Hash`
  #
  # @param [String] string
  # @return [Hash]
  def string_to_hash(string)
    JSON.parse(string.gsub("=>", ":"))
  end

  # Formats the linkage data for `path_values` into a kind which can be parsed
  # by the `string_to_hash` method. Converts ruby `Set`s to `Array`s.
  #
  # @param  [Hash(String, Set(String))] hash
  # @return [Hash(String, Array(String))]
  def format_path_values(hash)
    hash.each_with_object({}) { |(k, v), h| h[k] = v.to_a }
  end

  # Formats the linkage data for `hash_values` into a kind which can be parsed
  # by the `string_to_hash` method. Converts ruby `Set`s to `Array`s, and
  # converts ruby `Pathname`s to `String`s
  #
  # @param  [Hash(String, Set(Pathname))] hash
  # @return [Hash(String, Array(String))]
  def format_hash_values(hash)
    hash.each_with_object({}) do |(outer_key, outer_values), outer_hash|
      outer_hash[outer_key] = outer_values.each_with_object({}) do |(k, v), h|
        h[k] = v.to_a.map(&:to_s)
      end
    end
  end
end
