module AlmaStubbing
  def stub_alma_ids(ids:, status:, fixture: nil)
    alma_path = Pathname.new(file_fixture_path).join("alma")
    json_body = alma_path.join("#{fixture}.json")
    ids = Array.wrap(ids)
    stub_request(:get, "https://api-na.hosted.exlibrisgroup.com/almaws/v1/bibs?expand=p_avail,e_avail,d_avail,requests&mms_id=#{ids.join(',')}")
      .to_return(status: status, body: json_body)
    all_items_path = alma_path.join("#{fixture}_all_items.json")
    return unless all_items_path.exist?
    stub_request(:get, "https://api-na.hosted.exlibrisgroup.com/almaws/v1/bibs/#{ids.first}/holdings/ALL/items")
      .to_return(status: status, body: all_items_path, headers: { 'Content-Type' => 'application/json' })
  end
end

RSpec.configure do |config|
  config.include AlmaStubbing
end
