require 'faraday'
require 'active_support/core_ext/string'

# Cached mapping of ARKs to Bib IDs
# Retrieves and stores paginated Solr responses containing the ARK's and BibID's
class CacheMap

  def self.cache_key_for(ark:)
    ark.gsub(/[\:\/]/, '_')
  end

  # Constructor
  # @param cache [ActiveSupport::Cache::Store, CacheAdapter] Low-level cache
  # @param host [String] the host for the Blacklight endpoint
  # @param path [String] the path for the Blacklight endpoint
  # @param rows [Integer] the number of rows for each Solr response
  # @param logger [IO] the logging device
  def initialize(cache:, host:, path: '/catalog.json', rows: 1000000, logger: STDOUT)
    @cache = cache
    @host = host
    @path = path
    @rows = rows
    @logger = logger

    @logger.info "Seeding the cache for #{@host} using Solr..."
    seed!
  end

  # Seed the cache
  # @param page [Integer] the page number at which to start the caching
  def seed!(page: 1)
    # Determine if the values from the Solr response have been cached
    @cached_values = @cache.fetch(cache_key)
    return if page == 1 && !@cached_values.nil?

    response = query(page: page)
    if response.empty?
      @logger.warn "No response could be retrieved from Solr for #{@host}"
      return
    end

    pages = response.fetch('pages')

    cache_page(response)

    # Recurse if there are more pages to cache
    if pages.fetch('last_page?') == false
      seed!(page: page + 1)
    else
      # Otherwise, mark within the cache that a thread has populated all of the ARK/BibID pairs
      @cache.write(cache_key, cache_key)
    end
  end

  # Fetch a BibID from the cache
  # @param ark [String] the ARK mapped to the BibID
  # @return [String, nil] the BibID (or nil if it has not been mapped)
  def fetch(ark)
    # Attempt to retrieve this from the cache
    value = @cache.fetch(self.class.cache_key_for(ark: ark))

    if value.nil?
      @logger.warn "Failed to resolve #{ark}" if URI::ARK.ark?(url: ark)
    else
      @logger.debug "Resolved #{ark} for #{value}"
    end
    value
  end

  private

    # Cache a page
    # @param page [Hash] Solr response page
    def cache_page(page)
      docs = page.fetch('docs')
      docs.each do |doc|
        arks = doc.fetch('identifier_ssim', [])
        bib_ids = doc.fetch('source_metadata_identifier_ssim', [])
        id = doc.fetch('id')
        # Grab the human readable type
        resource_types = doc.fetch('internal_resource_ssim', nil) || doc.fetch('has_model_ssim', nil)
        resource_type = resource_types.first

        ark = arks.first
        bib_id = bib_ids.first

        # Write this to the file cache
        key_for_ark = self.class.cache_key_for(ark: ark)
        # Handle collisions by refusing to overwrite the first value
        unless @cache.exist?(key_for_ark)
          @cache.write(key_for_ark, { id: id, source_metadata_identifier: bib_id, internal_resource: resource_type })
          @logger.debug "Cached the mapping for #{ark} to #{bib_id}"
        end
      end
    end

    # Query the service using the endpoint
    # @param [Integer] the page parameter for the query
    def query(page: 1)
      begin
        url = URI::HTTPS.build(host: @host, path: @path, query: "q=&rows=#{@rows}&page=#{page}&f[identifier_tesim][]=ark")
        http_response = Faraday.get(url)
        values = JSON.parse(http_response.body)
        values.fetch('response')
      rescue StandardError => err
        @logger.error "Failed to seed the ARK cached from Solr: #{err}"
        {}
      end
    end

    # Generate the unique key for the cache from the hostname and path for Solr
    # @return [String] the cache key
    def cache_key
      [@host.gsub(/[\.\/]/, '_'), @path.gsub(/[\.\/]/, '_')].join('_')
    end
end
