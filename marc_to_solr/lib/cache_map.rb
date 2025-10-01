require 'faraday'
require 'active_support/core_ext/string'
require 'active_support/core_ext/object/blank'

# Cached mapping of ARKs to Bib IDs
# Retrieves and stores paginated Solr responses containing the ARK's and BibID's
class CacheMap
  def self.cache_key_for(ark:)
    ark.gsub(%r{[:/]}, '_')
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
  end

  def seed!(page: 1)
    @logger.info "Seeding the cache for #{@host} using Solr..."
    # Determine if the values from the Solr response have been cached
    @cached_values = @cache.fetch(cache_key)
    return if page == 1 && !@cached_values.nil?

    response = query(page:)
    if response.empty?
      @logger.warn "No response could be retrieved from Solr for #{@host}"
      return
    end

    # Check for meta key
    unless response.key?('meta')
      @logger.error "Invalid response format from Solr: missing 'meta' key. Response: #{response.inspect}"
      return
    end

    meta = response['meta']
    unless meta&.key?('pages')
      @logger.error "Invalid response format from Solr: missing 'pages' in meta. Meta: #{meta.inspect}"
      return
    end
    pages = meta['pages']

    cache_page(response)

    # Recurse if there are more pages to cache
    if pages.fetch('last_page?', true) == false
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
    value = @cache.fetch(self.class.cache_key_for(ark:))

    if value.nil?
      @logger.warn "Failed to resolve #{ark}" if URI::ARK.princeton_ark?(url: ark)
    else
      @logger.debug "Resolved #{ark} for #{value}"
    end
    value
  end

  private

    def cache_page(page)
      docs = page.fetch('data')

      docs.each do |doc|
        next unless process_doc?(doc)

        ark = extract_ark(doc)
        next if ark.blank?

        bib_id = extract_bib_id(doc)
        next if bib_id.blank?

        cache_document_mapping(doc, ark, bib_id)
      end
    end

    def process_doc?(doc)
      resource_type = doc.fetch('type', [])
      excluded_types = ['Issue', 'Ephemera Folder', 'Coin']
      !excluded_types.include?(resource_type)
    end

    def extract_ark(doc)
      attributes = doc.dig('attributes', 'identifier_ssim')
      return nil unless attributes

      attributes.dig('attributes', 'value') || []
    end

    def extract_bib_id(doc)
      attributes = doc.dig('attributes', 'source_metadata_identifier_ssim')
      return nil unless attributes

      attributes.dig('attributes', 'value') || []
    end

    def cache_document_mapping(doc, ark, bib_id)
      id = doc.fetch('id')
      resource_type = doc.fetch('type', [])
      key_for_ark = self.class.cache_key_for(ark:)

      # Don't overwrite existing cache entries
      return if @cache.exist?(key_for_ark)

      cache_data = {
        id:,
        source_metadata_identifier: bib_id,
        internal_resource: resource_type
      }

      @cache.write(key_for_ark, cache_data)
      @logger.debug "Cached mapping for #{ark} to #{bib_id}"
    end

    # Query the service using the endpoint
    # @param [Integer] the page parameter for the query
    def query(page: 1)
      begin
        url = URI::HTTPS.build(host: @host, path: @path, query: "q=&rows=#{@rows}&page=#{page}&f[identifier_tesim][]=ark")
        http_response = Faraday.get(url)
        values = JSON.parse(http_response.body)
      rescue StandardError => e
        @logger.error "Failed to seed the ARK cached from Solr: #{e}"
        {}
      end
    end

    # Generate the unique key for the cache from the hostname and path for Solr
    # @return [String] the cache key
    def cache_key
      [@host.gsub(%r{[./]}, '_'), @path.gsub(%r{[./]}, '_')].join('_')
    end
end
