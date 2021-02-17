require "net/http"
require "json"

# This class is to allow us to delete Solr records with our current 
# version of Traject. Once we upgrade to Traject version 3.1 or later
# we could use Traject's native delete feature
# (see https://github.com/traject/traject/commit/c731d09c6cb15fbe572e4a294a7a127b525b7277)
# but keep in mind that this feature is still in experimental mode in Traject
# and their implementation does not support batches.
class SolrDeleter
  def initialize(solr_url)
    @solr_url = solr_url
  end

  def delete(ids, batch_size = 100)
    return if ids.count == 0
    # TODO: break the update into batches
    url = @solr_url + "/update?commit=true&wt=json"
    payload = "<delete>" + ids.map {|id| "<id>#{id}</id>"}.join("") + "</delete>"
    content_type = "text/xml" # request payload is in XML (even if the response is in JSON)
    http_post(url, payload, content_type)
  end

  private
    def http_post(url, payload, content_type)
      uri = URI.parse(url)
      http = Net::HTTP.new(uri.host, uri.port)
      if url.start_with?("https://")
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end
      request = Net::HTTP::Post.new(uri.request_uri)
      request["Content-Type"] = content_type
      request.body = payload
      response = http.request(request)
      response        
    end
end