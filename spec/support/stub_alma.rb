module AlmaStubbing
  def stub_alma_ids(ids:, status:, fixture: nil)
    ids = Array.wrap(ids)
    alma_path = Pathname.new(file_fixture_path).join('alma')
    json_body = alma_path.join("#{fixture || ids.join('')}.json")
    stub_request(:get, "https://api-na.hosted.exlibrisgroup.com/almaws/v1/bibs?expand=p_avail,e_avail,d_avail,requests&mms_id=#{ids.join(',')}")
      .to_return(status:, body: json_body)
    all_items_path = alma_path.join("#{fixture}_all_items.json")
    return unless all_items_path.exist?

    stub_request(:get, "https://api-na.hosted.exlibrisgroup.com/almaws/v1/bibs/#{ids.first}/holdings/ALL/items")
      .to_return(status:, body: all_items_path, headers: { 'Content-Type' => 'application/json' })
  end

  def stub_alma_bib_items(mms_id:, filename:, status: 200, limit: 100, offset: nil)
    alma_path = Pathname.new(file_fixture_path).join('alma')
    url =  "https://api-na.hosted.exlibrisgroup.com/almaws/v1/bibs/#{mms_id}/holdings/ALL/items?expand=due_date_policy,due_date&order_by=library&direction=asc&limit=#{limit}"
    url += "&offset=#{offset}" if offset
    stub_request(:get, url)
      .to_return(
        status:,
        headers: { 'content-Type' => 'application/json' },
        body: alma_path.join(filename)
      )
  end

  def stub_alma_holding(mms_id:, holding_id:)
    alma_path = Pathname.new(file_fixture_path).join('alma')
    stub_request(:get, %r{.*\.exlibrisgroup\.com/almaws/v1/bibs/#{mms_id}/holdings/#{holding_id}$})
      .to_return(status: 200,
                 headers: { 'Content-Type' => 'application/json' },
                 body: alma_path.join("holding_#{holding_id}.json"))
  end

  def stub_alma_holding_items(mms_id:, holding_id:, filename:, query: 'limit=100', status: 200)
    alma_path = Pathname.new(file_fixture_path).join('alma')
    query_string = [query, 'order_by=enum_a'].compact_blank.join('&')
    stub_request(:get, "https://api-na.hosted.exlibrisgroup.com/almaws/v1/bibs/#{mms_id}/holdings/#{holding_id}/items?#{query_string}")
      .to_return(status:,
                 headers: { 'Content-Type' => 'application/json' },
                 body: alma_path.join(filename))
  end

  def stub_alma_item_barcode(mms_id:, item_id:, barcode:, holding_id:)
    alma_path = Pathname.new(file_fixture_path).join('alma')
    stub_request(:get, %r{.*\.exlibrisgroup\.com/almaws/v1/items.*})
      .with(query: { item_barcode: barcode })
      .to_return(status: 302,
                 headers: { 'Location' => "https://api-na.hosted.exlibrisgroup.com/almaws/v1/bibs/#{mms_id}/holdings/#{holding_id}/items/#{item_id}" })
    stub_request(:get, %r{.*\.exlibrisgroup\.com/almaws/v1/bibs/#{mms_id}/holdings/#{holding_id}/items/#{item_id}.*})
      .to_return(status: 200,
                 headers: { 'Content-Type' => 'application/json' },
                 body: alma_path.join("barcode_#{barcode}.json"))
  end

  def stub_alma_library(library_code:, location_code:, body: '{}')
    stub_request(:get, "https://api-na.hosted.exlibrisgroup.com/almaws/v1/conf/libraries/#{library_code}/locations/#{location_code}")
      .with(headers: stub_alma_request_headers)
      .to_return(status: 200, body:, headers: { 'content-Type' => 'application/json' })
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

  def stub_alma_request_headers
    {
      'Accept' => 'application/json',
      'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
      'Authorization' => 'apikey TESTME',
      'Content-Type' => 'application/json',
      'User-Agent' => 'Ruby'
    }
  end

  def stub_sru(cql_query, fixture_file_name, maximum_records = 1)
    stub_request(:get, "#{Rails.configuration.alma['sru_url']}?maximumRecords=#{maximum_records}&operation=searchRetrieve&query=#{cql_query}&recordSchema=marcxml&version=1.2")
      .to_return(status: 200, body: file_fixture("alma/sru/#{fixture_file_name}.xml"))
  end
end

RSpec.configure do |config|
  config.include AlmaStubbing
end
