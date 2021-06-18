require 'rails_helper'

RSpec.describe AlmaAdapter do
  subject(:adapter) { described_class.new }

  let(:unsuppressed) { "991227850000541" }
  let(:unsuppressed_two) { "991227840000541" }
  let(:unsuppressed_two_loc_two_items) { "99223608406421" }
  let(:suppressed) { "99222441306421" }
  let(:unsuppressed_two_holdings_fixture) { file_fixture("alma/#{unsuppressed_two}_holdings.xml") }

  before do
    stub_request(:get, "https://alma/almaws/v1/bibs/#{unsuppressed}/holdings?apikey=TESTME")
      .to_return(status: 200, body: unsuppressed_two_holdings_fixture, headers: {
                   'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
                   'Content-Type' => 'application/xml;charset=UTF-8',
                   'Accept' => 'application/xml',
                   'User-Agent' => 'Faraday v1.0.1'
                 })
    stub_alma_bib_items(
      mms_id: unsuppressed,
      filename: "bib_items_list_#{unsuppressed}.json"
    )
    stub_alma_bib_items(
      mms_id: unsuppressed_two_loc_two_items,
      filename: "#{unsuppressed_two_loc_two_items}_two_locations_two_items.json"
    )
  end

  describe "#get_bib_record" do
    context "when an unsuppressed bib is provided" do
      it "returns one record" do
        unsuppressed_id = "991227850000541"
        stub_alma_ids(ids: unsuppressed_id, status: 200, fixture: "unsuppressed_991227850000541")
        expect(adapter.get_bib_record(unsuppressed_id)['001'].value).to eq "991227850000541"
      end
    end
    context "when a suppressed bib is provided" do
      it "returns nil" do
        id = "99222441306421"
        stub_alma_ids(ids: id, status: 200, fixture: "suppressed_#{id}")
        expect(adapter.get_bib_record(suppressed)).to be nil
      end
    end
    context "when a record is not found" do
      it "returns nil" do
        stub_alma_ids(ids: "1234", status: 200, fixture: "not_found")

        expect(adapter.get_bib_record("1234")).to be nil
      end
    end
    context "when a bad ID is given" do
      it "returns nil" do
        stub_alma_ids(ids: "bananas", status: 400, fixture: "bad_request")

        expect(adapter.get_bib_record("bananas")).to be nil
      end
    end

    context "record with no physical inventory" do
      it "doesn't have an AVA tag" do
        id = "99171146000521"
        stub_alma_ids(ids: id, status: 200, fixture: "#{id}_no_AVA")

        expect(adapter.get_bib_record(id)['AVA']).to be nil
      end
    end

    context "record with electronic inventory" do
      it "has an AVE tag" do
        id = "99171146000521"
        stub_alma_ids(ids: id, status: 200, fixture: "#{id}_no_AVA")

        expect(adapter.get_bib_record(id)['AVE']).not_to be nil
      end
    end
  end

  describe "#get_bib_records" do
    context "if a string of bibs is provided" do
      it "returns multiple unsuppressed records" do
        ids = ["991227850000541", "991227840000541", "99222441306421"]
        stub_alma_ids(ids: ids, status: 200, fixture: "unsuppressed_suppressed")

        expect(adapter.get_bib_records(ids)[0]['001'].value).to eq unsuppressed_two
        expect(adapter.get_bib_records(ids)[1]['001'].value).to eq unsuppressed
        expect(adapter.get_bib_records(ids).count).to eq 2
      end
    end
  end

  describe '#get_holding_records' do
    it "returns the holdings for a bib" do
      expect(adapter.get_holding_records(unsuppressed)).to be_a(String)
    end
  end

  describe "#get_items_for_bib" do
    context "A record with two locations, two items in each location" do
      it "returns the item as a set" do
        set = adapter.get_items_for_bib(unsuppressed_two_loc_two_items)
        expect(set.map(&:composite_location).uniq).to eq ["MAIN$offsite", "MAIN$RESERVES"]
        expect(set.count).to eq 4
      end
      it "paginates items" do
        stub_const("Alma::BibItemSet::ITEMS_PER_PAGE", 2)
        stub_alma_bib_items(
          mms_id: unsuppressed_two_loc_two_items,
          limit: 2,
          filename: "#{unsuppressed_two_loc_two_items}_two_locations_two_items_page_1.json"
        )
        stub_alma_bib_items(
          mms_id: unsuppressed_two_loc_two_items,
          limit: 2,
          offset: 2,
          filename: "#{unsuppressed_two_loc_two_items}_two_locations_two_items_page_2.json"
        )
        set = adapter.get_items_for_bib(unsuppressed_two_loc_two_items)
        expect(set.map(&:composite_location).uniq).to eq ["MAIN$offsite", "MAIN$RESERVES"]
        expect(set.count).to eq 3
      end
    end
  end

  describe "a record that has an ARK" do
    xit "exposes the ark" do
      # find an alma record with an ark.princeton.edu
    end
  end

  describe "a record with no item" do
    # it has a holding
    # it doesn't have an item. This should be checked on the Holding
    xit "has a holding" do
    end
  end

  describe "catalog date" do
    let(:bib_record) { file_fixture("alma/99122426947506421.json") }
    let(:bib_record_with_ava) { file_fixture("alma/9922486553506421.json") }
    let(:bib_record_with_ava_holdings) { file_fixture("alma/9922486553506421_holdings.json") }

    before do
      stub_request(:get, "https://api-na.hosted.exlibrisgroup.com/almaws/v1/bibs?expand=p_avail,e_avail,d_avail,requests&mms_id=99122426947506421")
        .with(headers: stub_alma_request_headers)
        .to_return(status: 200, body: bib_record, headers: { "content-Type" => "application/json" })

      stub_request(:get, "https://api-na.hosted.exlibrisgroup.com/almaws/v1/bibs?expand=p_avail,e_avail,d_avail,requests&mms_id=9922486553506421")
        .with(headers: stub_alma_request_headers)
        .to_return(status: 200, body: bib_record_with_ava, headers: { "content-Type" => "application/json" })

      stub_request(:get, "https://api-na.hosted.exlibrisgroup.com/almaws/v1/bibs/9922486553506421/holdings/ALL/items?direction=asc&expand=due_date_policy,due_date&limit=100&order_by=library")
        .with(headers: stub_alma_request_headers)
        .to_return(status: 200, body: bib_record_with_ava_holdings, headers: { "content-Type" => "application/json" })
    end

    it "uses date from AVA fields" do
      record = adapter.get_bib_record("9922486553506421")
      date = adapter.get_catalog_date_from_record(record)
      expect(date).to eq "2020-12-03Z"
    end

    it "defaults to date in bib record (when neither AVA nor AVE exist)" do
      record = adapter.get_bib_record("99122426947506421")
      date = adapter.get_catalog_date_from_record(record)
      expect(date).to eq "2016-01-23Z"
    end
  end

  describe "record availability" do
    let(:bib_record_with_ava) { file_fixture("alma/9922486553506421.json") }
    let(:bib_record_with_ava_holding_items) { file_fixture("alma/9922486553506421_holding_items.json") }
    let(:bib_record_with_cdl) { file_fixture("alma/9965126093506421.json") }
    let(:bib_record_with_cdl_holding_items) { file_fixture("alma/9965126093506421_holding_items.json") }
    let(:bib_record_with_ave) { file_fixture("alma/99122426947506421.json") }
    let(:bib_record_with_av_other) { file_fixture("alma/9952822483506421.json") }
    let(:two_bib_records) { file_fixture("alma/two_bibs.json") }
    let(:bib_record_with_some_available) { file_fixture("alma/9921799253506421.json") }
    let(:library_lewis_reserves) { file_fixture("alma/library_lewis_reserves.json") }

    before do
      stub_request(:get, "https://api-na.hosted.exlibrisgroup.com/almaws/v1/bibs?expand=p_avail,e_avail,d_avail,requests&mms_id=9922486553506421")
        .with(headers: stub_alma_request_headers)
        .to_return(status: 200, body: bib_record_with_ava, headers: { "content-Type" => "application/json" })

      stub_request(:get, "https://api-na.hosted.exlibrisgroup.com/almaws/v1/bibs/9922486553506421/holdings/ALL/items")
        .with(headers: stub_alma_request_headers)
        .to_return(status: 200, body: bib_record_with_ava_holding_items, headers: { "content-Type" => "application/json" })

      stub_request(:get, "https://api-na.hosted.exlibrisgroup.com/almaws/v1/bibs?expand=p_avail,e_avail,d_avail,requests&mms_id=9965126093506421")
        .with(headers: stub_alma_request_headers)
        .to_return(status: 200, body: bib_record_with_cdl, headers: { "content-Type" => "application/json" })

      stub_request(:get, "https://api-na.hosted.exlibrisgroup.com/almaws/v1/bibs/9965126093506421/holdings/ALL/items")
        .with(headers: stub_alma_request_headers)
        .to_return(status: 200, body: bib_record_with_cdl_holding_items, headers: { "content-Type" => "application/json" })

      stub_request(:get, "https://api-na.hosted.exlibrisgroup.com/almaws/v1/bibs?expand=p_avail,e_avail,d_avail,requests&mms_id=9952822483506421")
        .with(headers: stub_alma_request_headers)
        .to_return(status: 200, body: bib_record_with_av_other, headers: { "content-Type" => "application/json" })

      stub_request(:get, "https://api-na.hosted.exlibrisgroup.com/almaws/v1/bibs?expand=p_avail,e_avail,d_avail,requests&mms_id=99122426947506421")
        .with(headers: stub_alma_request_headers)
        .to_return(status: 200, body: bib_record_with_ave, headers: { "content-Type" => "application/json" })

      stub_request(:get, "https://api-na.hosted.exlibrisgroup.com/almaws/v1/bibs?expand=p_avail,e_avail,d_avail,requests&mms_id=9922486553506421,99122426947506421")
        .with(headers: stub_alma_request_headers)
        .to_return(status: 200, body: two_bib_records, headers: {})

      stub_request(:get, "https://api-na.hosted.exlibrisgroup.com/almaws/v1/bibs?expand=p_avail,e_avail,d_avail,requests&mms_id=9921799253506421")
        .with(headers: stub_alma_request_headers)
        .to_return(status: 200, body: bib_record_with_some_available, headers: { "content-Type" => "application/json" })

      stub_alma_library(library_code: "lewis", location_code: "resterm", body: library_lewis_reserves)
      stub_alma_library(library_code: "online", location_code: "etasrcp")
      stub_alma_library(library_code: "recap", location_code: "pa")
      stub_alma_library(library_code: "firestone", location_code: "stacks")

      stub_alma_ids(ids: "9959958323506421", status: 200, fixture: "9959958323506421")
      stub_alma_holding_items(mms_id: "9959958323506421", holding_id: "ALL", filename: "9959958323506421_items.json", query: "")
    end

    it "reports availability of physical holdings" do
      FactoryBot.create(:holding_location, code: 'firestone$stacks', label: 'Stacks')
      availability = adapter.get_availability_one(id: "9922486553506421")
      holding = availability["9922486553506421"]["22117511410006421"]
      expect(holding[:status_label]).to eq "Unavailable"
      expect(holding[:label]).to eq "Firestone Library - Stacks"
      expect(holding[:location]).to eq "firestone$stacks"
      expect(holding[:cdl]).to eq false
    end

    it "reports CDL when available" do
      FactoryBot.create(:holding_location, code: 'firestone$stacks', label: 'Stacks')
      availability = adapter.get_availability_one(id: "9965126093506421")
      holding = availability["9965126093506421"]["22202918790006421"]
      expect(holding[:status_label]).to eq "Unavailable"
      expect(holding[:cdl]).to eq true
      expect(holding[:label]).to eq 'Firestone Library - Stacks'
    end

    it "reports some items available" do
      availability = adapter.get_availability_one(id: "9921799253506421")
      holding = availability["9921799253506421"]["22201236200006421"]
      expect(holding[:status_label]).to eq "Some items not available"
    end

    it "ignores electronic resources" do
      availability = adapter.get_availability_one(id: "99122426947506421")
      empty_availability = { "99122426947506421" => {} }
      expect(availability).to eq empty_availability
    end

    it "reports availability (without holding_id) for items in temporary locations" do
      availability = adapter.get_availability_one(id: "9952822483506421")
      fake_holding = availability["9952822483506421"]["fake_id_1"]
      expect(fake_holding[:id]).to eq "fake_id_1"
      expect(fake_holding[:status_label]).to eq "Available"
      expect(fake_holding[:temp_location]).to eq true
      expect(fake_holding[:on_reserve]).to eq "N"
    end

    it "reports availability (with holding_id) for items in temporary locations when requested" do
      FactoryBot.create(:holding_location, code: 'lewis$resterm', label: 'Term Loan Reserves')
      availability = adapter.get_availability_one(id: "9959958323506421", deep_check: true)
      holding1 = availability["9959958323506421"]["22272063570006421"]
      holding2 = availability["9959958323506421"]["22272063520006421"]
      expect(holding1[:status_label]).to eq "Available"
      expect(holding1[:temp_location]).to eq true
      expect(holding1[:on_reserve]).to eq "Y"
      expect(holding1[:copy_number]).to eq "1"
      expect(holding2[:copy_number]).to eq "2"
      expect(holding1[:label]).to eq 'Lewis Library - Term Loan Reserves'
    end

    it "reports course reserves when record is in library marked as such" do
      availability = adapter.get_availability_one(id: "9959958323506421")
      holding = availability["9959958323506421"]["fake_id_1"]
      expect(holding[:on_reserve]).to eq "Y"
    end

    it "reports availability for many bib ids" do
      availability = adapter.get_availability_many(ids: ["9922486553506421", "99122426947506421"])
      expect(availability.keys.count).to eq 2
    end
  end

  describe "holding availability" do
    before do
      stub_alma_ids(ids: "9922486553506421", status: 200)
      stub_alma_holding_items(mms_id: "9922486553506421", holding_id: "22117511410006421", filename: "9922486553506421_holding_items.json")
      stub_alma_ids(ids: "9919392043506421", status: 200)
      stub_alma_holding_items(mms_id: "9919392043506421", holding_id: "22105104420006421", filename: "9919392043506421_holding_items.json")
      stub_alma_ids(ids: "99122455086806421", status: 200)
      stub_alma_holding_items(mms_id: "99122455086806421", holding_id: "22477860740006421", filename: "99122455086806421_holding_items.json")
      stub_alma_library(library_code: "firestone", location_code: "dixn")
      stub_alma_library(library_code: "firestone", location_code: "stacks")
      stub_alma_library(library_code: "online", location_code: "etasrcp")
    end

    it "reports holdings availability" do
      FactoryBot.create(:holding_location, code: 'firestone$stacks', label: 'Stacks')
      FactoryBot.create(:holding_location, code: 'online$etasrcp', label: 'ReCAP')
      availability = adapter.get_availability_holding(id: "9922486553506421", holding_id: "22117511410006421")
      item = availability.first
      expect(availability.count).to eq 1
      expect(item[:barcode]).to eq "32101036144101"
      expect(item[:in_temp_library]).to eq false
      expect(item[:temp_library_code]).to eq nil
      expect(item[:label]).to eq 'Firestone Library - Stacks'

      # We are hard-coding this value to "N" to preserve the property in the response
      # but we are not really using this value anymore.
      expect(item[:on_reserve]).to eq "N"

      # Make sure temp locations are handled and the permanent location is preserved.
      availability = adapter.get_availability_holding(id: "9919392043506421", holding_id: "22105104420006421")
      item = availability.first
      expect(item[:in_temp_library]).to eq true
      expect(item[:temp_library_code]).to eq "online"

      # Test an actual response. These values are not particularly meaningful, but to make sure we don't
      # inadvertently change them when refactoring.
      item_test = { barcode: "32101080920208", id: "23105104390006421", holding_id: "22105104420006421", copy_number: "1",
                    status: "Available", status_label: "Item in place", status_source: "base_status", process_type: nil,
                    on_reserve: "N", item_type: "Gen", pickup_location_id: "online", pickup_location_code: "online",
                    location: "online$etasrcp", label: "Electronic Access - ReCAP", in_temp_library: true,
                    description: "g. 4, br. 7/8", enum_display: "g. 4, br. 7/8", chron_display: "",
                    temp_library_code: "online", temp_library_label: "Electronic Access - ReCAP",
                    temp_location_code: "online$etasrcp", temp_location_label: "Electronic Access - ReCAP" }
      expect(item).to eq item_test
    end

    it "defaults the pickup location to the library" do
      availability = adapter.get_availability_holding(id: "99122455086806421", holding_id: "22477860740006421")
      item = availability.first
      expect(item[:location]).to eq "firestone$dixn"
      expect(item[:pickup_location_id]).to eq "firestone"
      expect(item[:pickup_location_code]).to eq "firestone"
    end
  end

  describe "holding availability status fields" do
    before do
      stub_alma_ids(ids: "9965126093506421", status: 200)
      stub_alma_holding_items(mms_id: "9965126093506421", holding_id: "22202918790006421", filename: "9965126093506421_holding_items.json")
      stub_alma_ids(ids: "9943506421", status: 200)
      stub_alma_holding_items(mms_id: "9943506421", holding_id: "22261963850006421", filename: "9943506421_holding_items.json")
      stub_alma_library(library_code: "firestone", location_code: "stacks")
      stub_alma_library(library_code: "recap", location_code: "xr")
    end

    it "uses the work_order to calculate status" do
      availability = adapter.get_availability_holding(id: "9965126093506421", holding_id: "22202918790006421")
      item = availability.first
      expect(item[:status]).to eq "Not Available"
      expect(item[:status_label]).to eq "Controlled Digital Lending"
      expect(item[:status_source]).to eq "work_order"
    end

    it "uses the process_type to calculate status" do
      availability = adapter.get_availability_holding(id: "9943506421", holding_id: "22261963850006421")
      item = availability.find { |bib_item| bib_item[:id] == "23261963800006421" }
      expect(item[:status]).to eq "Not Available"
      expect(item[:status_label]).to eq "Transit"
      expect(item[:status_source]).to eq "process_type"
      expect(item[:process_type]).to eq "TRANSIT"
    end

    it "uses the base_status to calculate status" do
      availability = adapter.get_availability_holding(id: "9943506421", holding_id: "22261963850006421")
      item = availability.first
      expect(item[:status]).to eq "Available"
      expect(item[:status_label]).to eq "Item in place"
      expect(item[:status_source]).to eq "base_status"
    end
  end

  describe "ExLibris rate limit" do
    before do
      stub_request(:get, "https://api-na.hosted.exlibrisgroup.com/almaws/v1/bibs?expand=p_avail,e_avail,d_avail,requests&mms_id=9922486553506421")
        .with(headers: stub_alma_request_headers)
        .to_return(status: 429, body: stub_alma_per_second_threshold, headers: { "content-Type" => "application/json" })

      stub_request(:get, "https://api-na.hosted.exlibrisgroup.com/almaws/v1/bibs?expand=p_avail,e_avail,d_avail,requests&mms_id=9922486553506421,99122426947506421")
        .with(headers: stub_alma_request_headers)
        .to_return(status: 429, body: stub_alma_per_second_threshold, headers: { "content-Type" => "application/json" })

      stub_alma_ids(ids: "9919392043506421", status: 200)
      stub_request(:get, "https://api-na.hosted.exlibrisgroup.com/almaws/v1/bibs/9919392043506421/holdings/22105104420006421/items?limit=100")
        .to_return(status: 429, body: stub_alma_per_second_threshold, headers: { "Content-Type" => "application/json" })
    end

    it "handles per second threshold exception in single bib availability" do
      expect { adapter.get_availability_one(id: "9922486553506421") }.to raise_error(Alma::PerSecondThresholdError)
    end

    it "handles per second threshold exception in multi-bib availability" do
      expect { adapter.get_availability_many(ids: ["9922486553506421", "99122426947506421"]) }.to raise_error(Alma::PerSecondThresholdError)
    end

    it "handles per second threshold exception in holding availability" do
      expect { adapter.get_availability_holding(id: "9919392043506421", holding_id: "22105104420006421") }.to raise_error(Alma::PerSecondThresholdError)
    end
  end
end
