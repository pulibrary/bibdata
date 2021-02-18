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
      response = delete_batch(batch)
      raise StandardError, "Error deleting Solr documents. Status: #{response.status}. Body: #{response.body}" if response.status != 200
    end
  end

  private

    def delete_batch(batch)
      # Passes the ids to delete as a single XML document
      url = @solr_url + "/update?commit=true&wt=json"
      payload = "<delete>" + batch.map { |id| "<id>#{id}</id>" }.join("") + "</delete>"
      content_type = "text/xml" # request payload is XML (even if the response is in JSON via the wt=json param)
      @logger&.info "Deleting #{payload}"
      Faraday.post(url, payload, "Content-Type" => content_type)
    end
end
