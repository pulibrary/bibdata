# Class which provides an API similar to that of ActiveSupport::Cache::Store Objects
# Currently this just supports the Lightly Gem (@see https://github.com/DannyBen/lightly)
class CacheAdapter
  # Clear a directory path used by a caching service
  # @param dir [String] the path to the directory used by the cache
  def self.clear(dir:)
    # Ensure that the directory is empty
    base_path = File.expand_path(dir)
    glob_path = File.join(base_path, '**', '*')
    paths = Dir.glob(glob_path)
    FileUtils.rm_r(paths)
  end

  # Constructor
  # @param service [Lightly] the caching service
  def initialize(service:)
    @service = service
  end

  # Fetch a value from the cache
  # @param key [String] key for the cache
  # @return [Object, nil] the value (or nil if no objects have been cached)
  def fetch(key)
    return nil unless @service.cached?(key)

    @service.get(key)
  end

  # Write to the cache
  # @param key [String] key for the cache
  # @return [Object] the object being cached for the key
  def write(key, value)
    @service.clear(key)
    @service.get(key) do
      value
    end
  end

  # Determine whether or not a value for a given key has been cached
  # @param key [String] the key
  # @return [TrueClass, FalseClass]
  def exist?(key)
    @service.cached?(key)
  end
end
