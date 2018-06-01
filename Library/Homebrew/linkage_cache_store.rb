require "set"
require "cache_store"

#
# `LinkageCacheStore` provides methods to fetch and mutate linkage-specific data used
# by the `brew linkage` command
#
class LinkageCacheStore < CacheStore
  # @param  [String] keg_name
  # @param  [CacheStoreDatabase] database
  # @return [nil]
  def initialize(keg_name, database)
    @keg_name = keg_name
    super(database)
  end

  # Returns `true` if the database has any value for the current `keg_name`
  #
  # @return [Boolean]
  def keg_exists?
    !database.get(@keg_name).nil?
  end

  # Inserts dylib-related information into the cache if it does not exist or
  # updates data into the linkage cache if it does exist
  #
  # @param  [Hash] hash_values:  hash containing KVPs of { :type => Hash }
  # @return [nil]
  def update!(hash_values)
    hash_values.each_key do |type|
      next if HASH_LINKAGE_TYPES.include?(type)

      raise TypeError, <<~EOS
        Can't update types that are not defined for the linkage store
      EOS
    end

    database.set @keg_name, ruby_hash_to_json_string(hash_values)
  end

  # @param  [Symbol] the type to fetch from the `LinkageCacheStore`
  # @raise  [TypeError] error if the type is not in `HASH_LINKAGE_TYPES`
  # @return [Hash]
  def fetch_type(type)
    unless HASH_LINKAGE_TYPES.include?(type)
      raise TypeError, <<~EOS
        Can't fetch types that are not defined for the linkage store
      EOS
    end

    return {} unless keg_exists?

    fetch_hash_values(type)
  end

  # @return [nil]
  def flush_cache!
    database.delete(@keg_name)
  end

  private

  HASH_LINKAGE_TYPES = [:keg_files_dylibs].freeze

  # @param  [Symbol] type
  # @return [Hash]
  def fetch_hash_values(type)
    keg_cache = database.get(@keg_name)
    return {} unless keg_cache
    json_string_to_ruby_hash(keg_cache)[type.to_s]
  end
end
