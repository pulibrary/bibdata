module AlmaStubbing
  def stub_alma_ids(ids:, status:, fixture: nil)
    ids = Array.wrap(ids)
    alma_path = Pathname.new(file_fixture_path).join("alma")
    json_body = alma_path.join("#{fixture || ids.join('')}.json")
    stub_request(:get, "https://api-na.hosted.exlibrisgroup.com/almaws/v1/bibs?expand=p_avail,e_avail,d_avail,requests&mms_id=#{ids.join(',')}")
      .to_return(status: status, body: json_body)
    all_items_path = alma_path.join("#{fixture}_all_items.json")
    return unless all_items_path.exist?
    stub_request(:get, "https://api-na.hosted.exlibrisgroup.com/almaws/v1/bibs/#{ids.first}/holdings/ALL/items")
      .to_return(status: status, body: all_items_path, headers: { 'Content-Type' => 'application/json' })
  end

  def stub_alma_bib_items(mms_id:, status: 200, filename:, limit: 100, offset: nil)
    alma_path = Pathname.new(file_fixture_path).join("alma")
    url =  "https://api-na.hosted.exlibrisgroup.com/almaws/v1/bibs/#{mms_id}/holdings/ALL/items?expand=due_date_policy,due_date&order_by=library&direction=asc&limit=#{limit}"
    url += "&offset=#{offset}" if offset
    stub_request(:get, url)
      .to_return(
        status: status,
        headers: { "content-Type" => "application/json" },
        body: alma_path.join(filename)
      )
  end

  def stub_alma_holding(mms_id:, holding_id:)
    alma_path = Pathname.new(file_fixture_path).join("alma")
    stub_request(:get, /.*\.exlibrisgroup\.com\/almaws\/v1\/bibs\/#{mms_id}\/holdings\/#{holding_id}$/)
      .to_return(status: 200,
                 headers: { "Content-Type" => "application/json" },
                 body: alma_path.join("holding_#{holding_id}.json"))
  end

  def stub_alma_holding_items(mms_id:, holding_id:, filename:)
    alma_path = Pathname.new(file_fixture_path).join("alma")
    stub_request(:get, "https://api-na.hosted.exlibrisgroup.com/almaws/v1/bibs/#{mms_id}/holdings/#{holding_id}/items?limit=100")
      .to_return(status: 200,
                 headers: { "Content-Type" => "application/json" },
                 body: alma_path.join(filename))
  end

  def stub_alma_item_barcode(mms_id:, item_id:, barcode:, holding_id:)
    alma_path = Pathname.new(file_fixture_path).join("alma")
    stub_request(:get, /.*\.exlibrisgroup\.com\/almaws\/v1\/items.*/)
      .with(query: { item_barcode: barcode })
      .to_return(status: 302,
                 headers: { "Location" => "https://api-na.hosted.exlibrisgroup.com/almaws/v1/bibs/#{mms_id}/holdings/#{holding_id}/items/#{item_id}" })
    stub_request(:get, /.*\.exlibrisgroup\.com\/almaws\/v1\/bibs\/#{mms_id}\/holdings\/#{holding_id}\/items\/#{item_id}.*/)
      .to_return(status: 200,
                 headers: { "Content-Type" => "application/json" },
                 body: alma_path.join("barcode_#{barcode}.json"))
  end

  def stub_alma_per_second_threshold
    # Sources: https://developers.exlibrisgroup.com/alma/apis/#error
    #          and https://developers.exlibrisgroup.com/alma/apis/#threshold
    <<-HTTP_RESPONSE
      {
        "errorsExist": true,
        "errorList": {
          "error": [
            {
              "errorCode": "PER_SECOND_THRESHOLD",
              "errorMessage": "HTTP requests are more than allowed per second",
              "trackingId": "E01-0101190932-VOBYO-AWAE1554214409"
            }
          ]
        },
        "result": null
      }
    HTTP_RESPONSE
  end
end

RSpec.configure do |config|
  config.include AlmaStubbing
end
