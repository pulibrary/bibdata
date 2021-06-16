require "net/http"
require "json"

# This class allow us to delete Solr records with our current
# version of Traject. Once we upgrade to Traject version 3.1
# or later we could use Traject's native delete feature
# (see https://github.com/traject/traject/commit/c731d09c6cb15fbe572e4a294a7a127b525b7277)
# but keep in mind that Traject's implementation is still in experimental mode
# and it does not (yet) support batches.
class SolrDeleter
  def initialize(solr_url, logger = nil)
    @solr_url = solr_url
    @logger = logger
  end

  def delete(ids, batch_size = 100)
    ids.each_slice(batch_size) do |batch|
      delete_batch(batch)
    end
  end

  private

    # content_type = "text/xml"
    # request payload is XML (even if the response is in JSON via the wt=json param)
    def request_deletion(uri:, body:, content_type: 'text/xml')
      @logger&.info "Deleting #{body}"
      Faraday.post(uri) do |req|
        req.headers = { "Content-Type" => content_type }
        req.body = body
        req.options.open_timeout = 10
        req.options.read_timeout = 10
        req.options.write_timeout = 10
      end
    rescue Net::ReadTimeout => net_read_timeout
      Rails.logger.warn("Failed to transmit the POST request to #{uri}: #{body}")
    end

    def build_request_body(ids:)
      output = ["<delete>"]
      ids.each do |id|
        output << "<id>#{id}</id>"
      end

      output << "</delete>"
      output.join
    end

    def valid_response?(response)
      return false if response.nil?

      response.status == 200
    end

    def delete_batch(batch)
      uri = "#{@solr_url}/update?commit=true&wt=json"
      body = build_request_body(ids: batch)

      response = request_deletion(uri: uri, body: body)
      return if valid_response?(response)

      # Only retry once
      retry_response = request_deletion(uri: uri, body: body)
      return if valid_response?(retry_response)

      Honeybadger.notify("Error deleting Solr documents. IDs: #{batch.join(', ')}. Status: #{retry_response.status}. Body: #{retry_response.body}") unless retry_response.nil?
    end
end
