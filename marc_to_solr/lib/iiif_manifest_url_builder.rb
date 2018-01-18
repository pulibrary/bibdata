# Class for building instances of URI::HTTPS for IIIF Manifest URL's
class IIIFManifestUrlBuilder
  # Constructor
  # @param ark_cache [CompositeCacheMap] composite of caches for mapping ARK's to repository resource ID's
  # @param service_host [String] the host name for the repository instance
  # @todo Resolve the service_host default parameter properly (please @see https://github.com/pulibrary/marc_liberation/issues/313)
  def initialize(ark_cache:, service_host:)
    @ark_cache = ark_cache
    @service_host = service_host
  end

  # Generates an IIIF Manifest URL using an ARK
  # @param ark [URI::ARK] the archival resource key
  # @return URI::HTTPS the URL
  def build(url:)
    if url.is_a? URI::ARK
      cached_values = @ark_cache.fetch("ark:/#{url.naan}/#{url.name}")
      return if cached_values.nil?

      id = cached_values.fetch :id
      resource_type = cached_values.fetch :internal_resource
      human_readable_type = resource_type.underscore

      URI::HTTPS.build(host: @service_host, path: "/concern/#{human_readable_type.pluralize}/#{id}/manifest")
    end
  end
end
