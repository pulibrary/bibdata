# frozen_string_literal: true

# Class for building instances of URI::HTTPS for Orangelight URL's
class OrangelightUrlBuilder
  # Constructor
  # @param service_host [String] the host name for the Orangelight instance
  def initialize(fragment: 'view', service_host: 'catalog.princeton.edu')
    @service_host = service_host
    @fragment = fragment
  end

  # Generates an Orangelight URL using an ARK
  # @param ark [URI::ARK] the archival resource key
  # @return URI::HTTPS the URL
  def build(url:)
    if url.is_a? URI::ARK
      cached_bib_id = BibdataRs::Marc.mms_id("#{url.scheme}://#{url.hostname}/ark:/#{url.naan}/#{url.name}")
      return if cached_bib_id.nil?

      URI::HTTPS.build(host: @service_host, path: "/catalog/#{cached_bib_id}", fragment: @fragment)
    end
  end
end
