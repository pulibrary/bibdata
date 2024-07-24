# frozen_string_literal: true
class SolrStatus < HealthMonitor::Providers::Base
  def check!
    uri = URI.parse(Rails.application.config.solr['url'])
    status_uri = URI(uri.to_s.gsub(uri.path, "/solr/admin/cores?action=STATUS"))
    req = Net::HTTP::Get.new(status_uri)
    response = Net::HTTP.start(uri.hostname, uri.port) { |http| http.request(req) }
    json = JSON.parse(response.body)
    raise "The solr has an invalid status #{status_uri}" if json["responseHeader"]["status"] != 0
  end
end
