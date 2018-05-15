require "dbm"
require "json"

#
# `DatabaseCache` acts as an interface to a persistent storage mechanism
# residing in the `HOMEBREW_CACHE`
#
class DatabaseCache
  # The mode of any created files will be 0664 (that is, readable and writable
  # by the owner and the group, and readable by everyone else). Files created
  # will also be modified by the process' umask value at the time of creation:
  #   https://docs.oracle.com/cd/E17276_01/html/api_reference/C/envopen.html
  DATABASE_MODE = 0664

  # Returned value from `initialize` block
  attr_reader :return_value

  # Opens and yields a database in read/write mode. Closes the database after use
  #
  # @yield  [DBM] db
  # @return [nil]
  def initialize(name)
    # DBM::WRCREAT: Creates the database if it does not already exist
    @db = DBM.open("#{HOMEBREW_CACHE}/#{name}.db", DATABASE_MODE, DBM::WRCREAT)
    @return_value = yield(@db)
    @db.close
  end
end

#
# `CacheStore` provides methods to mutate and fetch data from a persistent
# storage mechanism
#
class CacheStore
  # @param  [DBM] database_cache
  # @return [nil]
  def initialize(database_cache)
    @database_cache = database_cache
  end

  # Inserts new values or updates existing cached values to persistent storage
  # mechanism
  #
  # @abstract
  def update!(*)
    raise NotImplementedError
  end

  # Fetches cached values in persistent storage according to the type of data
  # stored
  #
  # @abstract
  def fetch_type(*)
    raise NotImplementedError
  end

  # Deletes data from the cache based on a condition defined in a concrete class
  #
  # @abstract
  def flush_cache!
    raise NotImplementedError
  end

  protected

  # @return [DBM]
  attr_reader :database_cache

  # DBM stores ruby objects as a ruby `String`. Hence, when fetching the data,
  # to convert the ruby string back into a ruby `Hash`, the string is converted
  # into a JSON compatible string in `ruby_hash_to_json_string`, where it may
  # later be parsed by `JSON.parse` in the `json_string_to_ruby_hash` method
  #
  # @param  [Hash] ruby `Hash` to be converted to `JSON` string
  # @return [String]
  def ruby_hash_to_json_string(hash)
    hash.to_json
  end

  # @param  [String] `JSON` string to be converted to ruby `Hash`
  # @return [Hash]
  def json_string_to_ruby_hash(string)
    JSON.parse(string)
  end
end
