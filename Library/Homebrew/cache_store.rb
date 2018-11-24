require "json"

#
# `CacheStoreDatabase` acts as an interface to a persistent storage mechanism
# residing in the `HOMEBREW_CACHE`.
#
class CacheStoreDatabase
  # Yields the cache store database.
  # Closes the database after use if it has been loaded.
  #
  # @param  [Symbol] type
  # @yield  [CacheStoreDatabase] self
  def self.use(type)
    database = CacheStoreDatabase.new(type)
    return_value = yield(database)
    database.close_if_open!
    return_value
  end

  # Sets a value in the underlying database (and creates it if necessary).
  def set(key, value)
    db[key] = value
  end

  # Gets a value from the underlying database (if it already exists).
  def get(key)
    return unless created?

    db[key]
  end

  # Gets a value from the underlying database (if it already exists).
  def delete(key)
    return unless created?

    db.delete(key)
  end

  # Closes the underlying database (if it is created and open).
  def close_if_open!
    return unless @db
    cache_path.dirname.mkpath
    cache_path.atomic_write(JSON.dump(@db))
  end

  # Returns `true` if the cache file has been created for the given `@type`
  #
  # @return [Boolean]
  def created?
    cache_path.exist?
  end

  # Returns the modification time of the cache file (if it already exists).
  #
  # @return [Time]
  def mtime
    return unless created?
    cache_path.mtime
  end

  # Performs a `select` on the underlying database.
  #
  # @return [Array]
  def select(&block)
    db.select(&block)
  end

  # Returns `true` if the cache is empty.
  #
  # @return [Boolean]
  def empty?
    db.empty?
  end

  private

  # Lazily loaded database in read/write mode. If this method is called, a
  # database file with be created in the `HOMEBREW_CACHE` with name
  # corresponding to the `@type` instance variable
  #
  # @return [Hash] db
  def db
    @db ||= begin
      JSON.parse(cache_path.read) if created?
    rescue JSON::ParserError
      nil
    end
    @db ||= {}
  end

  # Creates a CacheStoreDatabase
  #
  # @param  [Symbol] type
  # @return [nil]
  def initialize(type)
    @type = type
  end

  # The path where the database resides in the `HOMEBREW_CACHE` for the given
  # `@type`
  #
  # @return [String]
  def cache_path
    HOMEBREW_CACHE/"#{@type}.json"
  end
end

#
# `CacheStore` provides methods to mutate and fetch data from a persistent
# storage mechanism.
#
class CacheStore
  # @param  [CacheStoreDatabase] database
  # @return [nil]
  def initialize(database)
    @database = database
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
  def fetch(*)
    raise NotImplementedError
  end

  # Deletes data from the cache based on a condition defined in a concrete class
  #
  # @abstract
  def delete!(*)
    raise NotImplementedError
  end

  protected

  # @return [CacheStoreDatabase]
  attr_reader :database
end
