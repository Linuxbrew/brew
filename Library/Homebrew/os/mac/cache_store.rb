require "dbm"
require "json"

#
# `DatabaseCache` acts as an interface to a persistent storage mechanism
# residing in the `HOMEBREW_CACHE`
#
class DatabaseCache
  # Users have read and write, but not execute permissions
  DATABASE_MODE = 0666

  # Opens and yields a database in read/write mode
  #
  # DBM::WRCREAT: Creates the database if it does not already exist
  def initialize(name)
    @db = DBM.open("#{HOMEBREW_CACHE}/#{name}.db", DATABASE_MODE, DBM::WRCREAT)
    yield(@db)
    @db.close
  end
end

#
# `CacheStore` provides methods to mutate and fetch data from a persistent
# storage mechanism
#
class CacheStore
  def initialize(database_cache)
    @database_cache = database_cache
  end

  # Inserts new values or updates existing cached values to persistent storage
  # mechanism
  def update!(*)
    raise NotImplementedError
  end

  # Fetches cached values in persistent storage according to the type of data
  # stored
  def fetch_type(*)
    raise NotImplementedError
  end

  # Deletes data from the cache based on a condition defined in a concrete class
  def flush_cache!
    raise NotImplementedError
  end

  protected

  attr_reader :database_cache

  # Parses `DBM` stored `String` into ruby `Hash`
  #
  # DBM stores ruby objects as a ruby `String`. Hence, when fetching the data,
  # to convert the ruby string back into a ruby `Hash`, the string is converted
  # into a JSON compatible string, where it may be parsed by the JSON.parse
  # function
  def string_to_hash(string)
    JSON.parse(string.gsub("=>", ":"))
  end
end

#
# `LinkageStore` provides methods to fetch and mutate linkage-specific data used
# by the `brew linkage` command
#
class LinkageStore < CacheStore
  HASH_LINKAGE_TYPES = [:brewed_dylibs, :reverse_links].freeze

  def initialize(keg_name, database_cache)
    @keg_name = keg_name
    super(database_cache)
  end

  def update!(
    path_values: {
      system_dylibs: %w[],
      variable_dylibs: %w[],
      broken_dylibs: %w[],
      indirect_deps: %w[],
      undeclared_deps:  %w[],
      unnecessary_deps: %w[],
    },
    hash_values: {
      brewed_dylibs: {},
      reverse_links: {},
    }
  )
    database_cache[keg_name] = {
      "path_values" => format_path_values(path_values),
      "hash_values" => format_hash_values(hash_values),
    }
  end

  def fetch_type(type)
    if HASH_LINKAGE_TYPES.include?(type)
      fetch_hash_values(type: type)
    else
      fetch_path_values(type: type)
    end
  end

  def flush_cache!
    database_cache.delete(keg_name)
  end

  private

  attr_reader :keg_name

  def fetch_path_values(type:)
    return [] if !database_cache.key?(keg_name) || database_cache[keg_name].nil?
    string_to_hash(database_cache[keg_name])["path_values"][type.to_s]
  end

  def fetch_hash_values(type:)
    return {} if !database_cache.key?(keg_name) || database_cache[keg_name].nil?
    string_to_hash(database_cache[keg_name])["hash_values"][type.to_s]
  end

  # Formats the linkage data for `path_values` into a kind which can be parsed
  # by the `string_to_hash` method. Converts ruby `Set`s to `Array`s
  def format_path_values(hash)
    hash.each_with_object({}) { |(k, v), h| h[k.to_s] = v.to_a }
  end

  # Formats the linkage data for `hash_values` into a kind which can be parsed
  # by the `string_to_hash` method. Converts ruby `Set`s to `Array`s, and
  # converts ruby `Pathname`s to `String`s
  def format_hash_values(hash)
    hash.each_with_object({}) do |(outer_key, outer_values), outer_hash|
      outer_hash[outer_key.to_s] = outer_values.each_with_object({}) do |(k, v), h|
        h[k] = v.to_a.map(&:to_s)
      end
    end
  end
end
