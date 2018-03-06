require "cache_store"

#
# `LinkageStore` provides methods to fetch and mutate linkage-specific data used
# by the `brew linkage` command
#
class LinkageStore < CacheStore
  ARRAY_LINKAGE_TYPES = [:system_dylibs, :variable_dylibs, :broken_dylibs,
                         :indirect_deps, :undeclared_deps, :unnecessary_deps].freeze
  HASH_LINKAGE_TYPES  = [:brewed_dylibs, :reverse_links].freeze

  # @param  [String] keg_name
  # @param  [DBM]    database_cache
  # @return [nil]
  def initialize(keg_name, database_cache)
    @keg_name = keg_name
    super(database_cache)
  end

  # Inserts dylib-related information into the cache if it does not exist or
  # updates data into the linkage cache if it does exist
  #
  # @param  [Hash]        array_values
  # @param  [Hash]        hash_values
  # @param  [Array[Hash]] values
  # @raise  [TypeError]
  # @return [nil]
  def update!(array_values: {}, hash_values: {}, **values)
    values.each do |key, value|
      if value.is_a? Hash
        hash_values[key] = value
      elsif value.is_a? Array
        array_values[key] = value
      else
        raise TypeError, "Can't store types that are not `Array` or `Hash` in the linkage store."
      end
    end

    database_cache[keg_name] = ruby_hash_to_json_string(
      array_values: format_array_values(array_values),
      hash_values: format_hash_values(hash_values),
    )
  end

  # @param  [Symbol] the type to fetch from the `LinkageStore`
  # @raise  [TypeError]
  # @return [Hash | Array]
  def fetch_type(type)
    if HASH_LINKAGE_TYPES.include?(type)
      fetch_hash_values(type)
    elsif ARRAY_LINKAGE_TYPES.include?(type)
      fetch_array_values(type)
    else
      raise TypeError, "Can't fetch types that are not defined for the linkage store."
    end
  end

  # @return [nil]
  def flush_cache!
    database_cache.delete(keg_name)
  end

  private

  # @return [String]
  attr_reader :keg_name

  # @param  [Symbol] type
  # @return [Array]
  def fetch_array_values(type)
    return [] unless database_cache.key?(keg_name)
    json_string_to_ruby_hash(database_cache[keg_name])["array_values"][type.to_s]
  end

  # @param  [Symbol] type
  # @return [Hash]
  def fetch_hash_values(type)
    return {} unless database_cache.key?(keg_name)
    json_string_to_ruby_hash(database_cache[keg_name])["hash_values"][type.to_s]
  end

  # Formats the linkage data for `array_values` into a kind which can be parsed
  # by the `json_string_to_ruby_hash` method. Internally converts ruby `Set`s to
  # `Array`s
  #
  # @param  [Hash]
  # @return [String]
  def format_array_values(hash)
    hash.each_with_object({}) { |(k, v), h| h[k] = v.to_a }
  end

  # Formats the linkage data for `hash_values` into a kind which can be parsed
  # by the `json_string_to_ruby_hash` method. Converts ruby `Set`s to `Array`s,
  # and converts ruby `Pathname`s to `String`s
  #
  # @param  [Hash]
  # @return [String]
  def format_hash_values(hash)
    hash.each_with_object({}) do |(outer_key, outer_values), outer_hash|
      outer_hash[outer_key] = outer_values.each_with_object({}) do |(k, v), h|
        h[k] = v.to_a.map(&:to_s)
      end
    end
  end
end
