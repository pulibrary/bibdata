require 'rails_helper'

RSpec.describe AlmaAdapter do
  subject(:adapter) { described_class.new }

  let(:unsuppressed) { '991227850000541' }
  let(:unsuppressed_two) { '991227840000541' }
  let(:unsuppressed_two_loc_two_items) { '99223608406421' }
  let(:suppressed) { '99222441306421' }
  let(:unsuppressed_two_holdings_fixture) { file_fixture("alma/#{unsuppressed_two}_holdings.xml") }

  before do
    stub_request(:get, "https://alma/almaws/v1/bibs/#{unsuppressed}/holdings?apikey=TESTME")
      .to_return(status: 200, body: unsuppressed_two_holdings_fixture, headers: {
                   'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
                   'Content-Type' => 'application/xml;charset=UTF-8',
                   'Accept' => 'application/xml'
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

  describe '#get_bib_record' do
    context 'when an unsuppressed bib is provided' do
      it 'returns one record' do
        stub_sru('alma.mms_tagSuppressed=false%20and%20alma.mms_id=991227850000541', '991227850000541')
        expect(adapter.get_bib_record(unsuppressed)['001'].value).to eq '991227850000541'
      end
    end

    context 'when a suppressed bib is provided' do
      it 'returns nil' do
        stub_sru('alma.mms_tagSuppressed=false%20and%20alma.mms_id=99222441306421', 'empty')
        expect(adapter.get_bib_record(suppressed)).to be_nil
      end
    end

    context 'when a record is not found' do
      it 'returns nil' do
        stub_sru('alma.mms_tagSuppressed=false%20and%20alma.mms_id=1234', 'empty')
        expect(adapter.get_bib_record('1234')).to be_nil
      end
    end

    context 'when a bad ID is given' do
      it 'returns nil' do
        expect(adapter.get_bib_record('bananas')).to be_nil
      end
    end
  end

  describe '#get_bib_records' do
    context 'if an array of bib ids is provided' do
      it 'returns multiple unsuppressed records' do
        ids = %w[991227850000541 991227840000541 99222441306421]
        stub_sru('alma.mms_tagSuppressed=false%20and%20alma.mms_id=991227850000541%20or%20alma.mms_id=991227840000541%20or%20alma.mms_id=99222441306421',
                 'unsuppressed_suppressed', 3)

        expect(adapter.get_bib_records(ids)[0]['001'].value).to eq unsuppressed
        expect(adapter.get_bib_records(ids)[1]['001'].value).to eq unsuppressed_two
        expect(adapter.get_bib_records(ids).count).to eq 2
      end
    end
  end

  describe '#get_holding_records' do
    it 'returns the holdings for a bib' do
      expect(adapter.get_holding_records(unsuppressed)).to be_a(String)
    end
  end

  describe '#get_items_for_bib' do
    context 'A record with two locations, two items in each location' do
      it 'returns the item as a set' do
        set = adapter.get_items_for_bib(unsuppressed_two_loc_two_items)
        expect(set.map(&:composite_location).uniq).to eq ['MAIN$offsite', 'MAIN$RESERVES']
        expect(set.count).to eq 4
      end

      it 'paginates items' do
        stub_const('Alma::BibItemSet::ITEMS_PER_PAGE', 2)
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
        expect(set.map(&:composite_location).uniq).to eq ['MAIN$offsite', 'MAIN$RESERVES']
        expect(set.count).to eq 3
      end
    end
  end

  describe 'record availability' do
    let(:bib_record_with_ava) { file_fixture('alma/9922486553506421.json') }
    let(:bib_record_with_ava_holding_items) { file_fixture('alma/9922486553506421_holding_items.json') }
    let(:bib_record_with_ave) { file_fixture('alma/99122426947506421.json') }
    let(:bib_record_with_av_other) { file_fixture('alma/9952822483506421.json') }
    let(:two_bib_records) { file_fixture('alma/two_bibs.json') }
    let(:bib_record_with_some_available) { file_fixture('alma/9921799253506421.json') }
    let(:library_lewis_reserves) { file_fixture('alma/library_lewis_reserves.json') }

    before do
      stub_request(:get, 'https://api-na.hosted.exlibrisgroup.com/almaws/v1/bibs?expand=p_avail,e_avail,d_avail,requests&mms_id=9922486553506421')
        .with(headers: stub_alma_request_headers)
        .to_return(status: 200, body: bib_record_with_ava, headers: { 'content-Type' => 'application/json' })

      stub_request(:get, 'https://api-na.hosted.exlibrisgroup.com/almaws/v1/bibs?expand=p_avail,e_avail,d_avail,requests&mms_id=9952822483506421')
        .with(headers: stub_alma_request_headers)
        .to_return(status: 200, body: bib_record_with_av_other, headers: { 'content-Type' => 'application/json' })

      stub_request(:get, 'https://api-na.hosted.exlibrisgroup.com/almaws/v1/bibs?expand=p_avail,e_avail,d_avail,requests&mms_id=99122426947506421')
        .with(headers: stub_alma_request_headers)
        .to_return(status: 200, body: bib_record_with_ave, headers: { 'content-Type' => 'application/json' })

      stub_request(:get, 'https://api-na.hosted.exlibrisgroup.com/almaws/v1/bibs?expand=p_avail,e_avail,d_avail,requests&mms_id=9922486553506421,99122426947506421')
        .with(headers: stub_alma_request_headers)
        .to_return(status: 200, body: two_bib_records, headers: {})

      stub_request(:get, 'https://api-na.hosted.exlibrisgroup.com/almaws/v1/bibs?expand=p_avail,e_avail,d_avail,requests&mms_id=9921799253506421')
        .with(headers: stub_alma_request_headers)
        .to_return(status: 200, body: bib_record_with_some_available, headers: { 'content-Type' => 'application/json' })

      stub_alma_library(library_code: 'lewis', location_code: 'resterm', body: library_lewis_reserves)
      stub_alma_library(library_code: 'recap', location_code: 'pa')
      stub_alma_library(library_code: 'firestone', location_code: 'stacks')
      stub_alma_library(library_code: 'rare', location_code: 'jrare')
      stub_alma_library(library_code: 'rare', location_code: 'scaex')
      stub_alma_library(library_code: 'lewis', location_code: 'mapmc')

      stub_alma_ids(ids: '9959958323506421', status: 200, fixture: '9959958323506421')
      stub_alma_holding_items(mms_id: '9959958323506421', holding_id: 'ALL', filename: '9959958323506421_items.json', query: '')

      stub_alma_ids(ids: '99111299423506421', status: 200, fixture: '99111299423506421')
      stub_alma_ids(ids: '9968442613506421', status: 200, fixture: '9968442613506421')
      stub_alma_ids(ids: '9922522883506421', status: 200, fixture: '9922522883506421')
    end

    it 'reports availability of physical holdings' do
      create(:holding_location, code: 'firestone$stacks', label: 'Stacks')
      availability = adapter.get_availability_one(id: '9922486553506421')
      holding = availability['9922486553506421']['22117511410006421']
      expect(holding[:status_label]).to eq 'Unavailable'
      expect(holding[:label]).to eq 'Firestone Library - Stacks'
      expect(holding[:location]).to eq 'firestone$stacks'
    end

    describe 'change_status Flipflop is turned on - Some Available' do
      before do
        allow(Flipflop).to receive(:change_status?).and_return(true)
      end

      it 'has status - Some Available' do
        availability = adapter.get_availability_one(id: '9921799253506421')
        holding = availability['9921799253506421']['22201236200006421']
        expect(holding[:status_label]).to eq 'Some Available'
      end
    end

    describe 'change_status Flipflop is turned off - Some items not available' do
      before do
        allow(Flipflop).to receive(:change_status?).and_return(false)
      end

      it 'has status - Some items not available' do
        availability = adapter.get_availability_one(id: '9921799253506421')
        holding = availability['9921799253506421']['22201236200006421']
        expect(holding[:status_label]).to eq 'Some items not available'
      end
    end

    it 'ignores electronic resources' do
      availability = adapter.get_availability_one(id: '99122426947506421')
      empty_availability = { '99122426947506421' => {} }
      expect(availability).to eq empty_availability
    end

    it 'reports availability (with holding_id) for items in temporary locations when requested' do
      create(:holding_location, code: 'lewis$resterm', label: 'Term Loan Reserves')
      availability = adapter.get_availability_one(id: '9959958323506421', deep_check: true)
      holding1 = availability['9959958323506421']['22272063570006421']
      holding2 = availability['9959958323506421']['22272063520006421']
      expect(holding1[:status_label]).to eq 'Available'
      expect(holding1[:temp_location]).to be true
      expect(holding1[:on_reserve]).to eq 'Y'
      expect(holding1[:copy_number]).to eq '1'
      expect(holding2[:copy_number]).to eq '2'
      expect(holding1[:label]).to eq 'Lewis Library - Term Loan Reserves'
    end

    it 'reports On-site access for aeon locations' do
      create(:aeon_location, code: 'rare$jrare', label: 'Special Collections')
      availability = adapter.get_availability_one(id: '99111299423506421')
      item = availability['99111299423506421']['22741556190006421']
      expect(item[:status_label]).to eq 'On-site Access'
    end

    it 'reports On-site access for some specific (map) locations' do
      create(:map_location, code: 'lewis$mapmc', label: 'Lewis Library - Map Collection. Map Case')
      availability = adapter.get_availability_one(id: '9968442613506421')
      item = availability['9968442613506421']['22692920560006421']
      expect(item[:status_label]).to eq 'On-site Access'
    end

    it 'reports On-site access for specific special collections locations' do
      create(:special_collection_location, code: 'rare$scaex', label: 'Special Collections - Rare Books Archival. Special Collections Use Only')
      availability = adapter.get_availability_one(id: '9922522883506421')
      item = availability['9922522883506421']['22943439460006421']
      expect(item[:status_label]).to eq 'On-site Access'
    end

    it 'does not have a dash (-) before the label when the label is missing' do
      create(:holding_location, code: 'firestone$stacks', label: '')
      availability = adapter.get_availability_one(id: '9922486553506421')
      holding = availability['9922486553506421']['22117511410006421']
      expect(holding[:label]).to eq 'Firestone Library'
    end

    it 'reports course reserves when record is in library marked as such' do
      availability = adapter.get_availability_one(id: '9959958323506421')
      holding = availability['9959958323506421']['lewis$resterm']
      expect(holding[:on_reserve]).to eq 'Y'
    end

    it 'reports availability for many bib ids' do
      availability = adapter.get_availability_many(ids: %w[9922486553506421 99122426947506421])
      expect(availability.keys.count).to eq 2
    end
  end

  describe 'holding availability' do
    let(:library_lewis_reserves) { file_fixture('alma/library_lewis_reserves.json') }
    let(:library_lewis_stacks) { file_fixture('alma/library_lewis_stacks.json') }

    before do
      stub_alma_holding_items(mms_id: '9919392043506421', holding_id: '22105104420006421', filename: '9919392043506421_holding_items.json')
      stub_alma_holding_items(mms_id: '99122455086806421', holding_id: '22477860740006421', filename: '99122455086806421_holding_items.json')
      stub_alma_library(library_code: 'firestone', location_code: 'dixn')
      stub_alma_library(library_code: 'firestone', location_code: 'stacks')

      # https://api-na.hosted.exlibrisgroup.com/almaws/v1/bibs/9999362473506421/holdings/22752541670006421/items?limit=100&order_by=enum_a
      stub_alma_holding_items(mms_id: '9999362473506421', holding_id: '22752541670006421', filename: '9999362473506421_holding_items.json')
      stub_alma_holding_items(mms_id: '9999362473506421', holding_id: '22752541690006421', filename: '9999362473506421_holding_items_two.json')

      stub_alma_library(library_code: 'lewis', location_code: 'resterm', body: library_lewis_reserves)
      stub_alma_library(library_code: 'lewis', location_code: 'stacks', body: library_lewis_stacks)
    end

    it 'reports holdings availability' do
      create(:holding_location, code: 'lewis$stacks', label: 'Stacks')
      create(:holding_location, code: 'lewis$resterm', label: 'Term Loan Reserves')
      availability = adapter.get_availability_holding(id: '9999362473506421', holding_id: '22752541670006421')

      item = availability.first
      expect(availability.count).to eq 1

      expect(item[:barcode]).to eq '32101098995671'
      expect(item[:in_temp_library]).to be false
      expect(item[:temp_library_code]).to be_nil
      expect(item[:label]).to eq 'Lewis Library - Stacks'
      expect(item[:requested]).to be false

      # We are hard-coding this value to "N" to preserve the property in the response
      # but we are not really using this value anymore.
      expect(item[:on_reserve]).to eq 'N'

      # Make sure temp locations are handled and the permanent location is preserved.
      availability = adapter.get_availability_holding(id: '9999362473506421', holding_id: '22752541690006421')
      item = availability.first
      expect(item[:in_temp_library]).to be true
      expect(item[:temp_library_code]).to eq 'lewis'

      # Test an actual response. These values are not particularly meaningful, but to make sure we don't
      # inadvertently change them when refactoring.
      item_test = { barcode: '32101099065268', id: '23752541680006421', holding_id: '22752541690006421', copy_number: '0',
                    status: 'Available', status_label: 'Item in place', status_source: 'base_status', process_type: nil,
                    on_reserve: 'Y', item_type: 'Gen', pickup_location_id: 'lewis', pickup_location_code: 'lewis',
                    location: 'lewis$resterm', label: 'Lewis Library - Term Loan Reserves', description: '', enum_display: '',
                    chron_display: '', requested: false, in_temp_library: true, temp_library_code: 'lewis',
                    temp_library_label: 'Lewis Library - Term Loan Reserves', temp_location_code: 'lewis$resterm',
                    temp_location_label: 'Lewis Library - Term Loan Reserves' }
      expect(item).to eq item_test
    end

    it 'defaults the pickup location to the library' do
      availability = adapter.get_availability_holding(id: '99122455086806421', holding_id: '22477860740006421')
      item = availability.first
      expect(item[:location]).to eq 'firestone$dixn'
      expect(item[:pickup_location_id]).to eq 'firestone'
      expect(item[:pickup_location_code]).to eq 'firestone'
    end

    it 'does not make unnecessary http requests' do
      adapter.get_availability_holding(id: '99122455086806421', holding_id: '22477860740006421')
      expect(WebMock).to have_requested(:get, /alma/).times(1)
    end
  end

  describe 'holding availability status fields' do
    before do
      stub_alma_ids(ids: '9965126093506421', status: 200)
      stub_alma_holding_items(mms_id: '9965126093506421', holding_id: '22202918790006421', filename: '9965126093506421_holding_items.json')
      stub_alma_ids(ids: '9943506421', status: 200)
      stub_alma_holding_items(mms_id: '9943506421', holding_id: '22261963850006421', filename: '9943506421_holding_items.json')
      stub_alma_library(library_code: 'firestone', location_code: 'stacks')
      stub_alma_library(library_code: 'recap', location_code: 'xr')
    end

    it 'uses the work_order to calculate status' do
      availability = adapter.get_availability_holding(id: '9965126093506421', holding_id: '22202918790006421')
      item = availability.first
      expect(item[:status]).to eq 'Unavailable'
      expect(item[:status_label]).to eq 'Holdings Management'
      expect(item[:status_source]).to eq 'work_order'
    end

    it 'uses the process_type to calculate status' do
      availability = adapter.get_availability_holding(id: '9943506421', holding_id: '22261963850006421')
      item = availability.find { |bib_item| bib_item[:id] == '23261963800006421' }
      expect(item[:status]).to eq 'Unavailable'
      expect(item[:status_label]).to eq 'Transit'
      expect(item[:status_source]).to eq 'process_type'
      expect(item[:process_type]).to eq 'TRANSIT'
    end

    it 'uses the base_status to calculate status' do
      availability = adapter.get_availability_holding(id: '9943506421', holding_id: '22261963850006421')
      item = availability.first
      expect(item[:status]).to eq 'Available'
      expect(item[:status_label]).to eq 'Item in place'
      expect(item[:status_source]).to eq 'base_status'
    end
  end

  describe 'ExLibris rate limit' do
    before do
      stub_request(:get, 'https://api-na.hosted.exlibrisgroup.com/almaws/v1/bibs?expand=p_avail,e_avail,d_avail,requests&mms_id=9922486553506421')
        .with(headers: stub_alma_request_headers)
        .to_return(status: 429, body: stub_alma_per_second_threshold, headers: { 'content-Type' => 'application/json' })

      stub_request(:get, 'https://api-na.hosted.exlibrisgroup.com/almaws/v1/bibs?expand=p_avail,e_avail,d_avail,requests&mms_id=9922486553506421,99122426947506421')
        .with(headers: stub_alma_request_headers)
        .to_return(status: 429, body: stub_alma_per_second_threshold, headers: { 'content-Type' => 'application/json' })

      stub_alma_ids(ids: '9919392043506421', status: 200)
      stub_request(:get, 'https://api-na.hosted.exlibrisgroup.com/almaws/v1/bibs/9919392043506421/holdings/22105104420006421/items?limit=100&order_by=enum_a')
        .to_return(status: 429, body: stub_alma_per_second_threshold, headers: { 'Content-Type' => 'application/json' })
    end

    it 'handles per second threshold exception in single bib availability' do
      expect { adapter.get_availability_one(id: '9922486553506421') }.to raise_error(Alma::PerSecondThresholdError)
    end

    it 'handles per second threshold exception in multi-bib availability' do
      expect { adapter.get_availability_many(ids: %w[9922486553506421 99122426947506421]) }.to raise_error(Alma::PerSecondThresholdError)
    end

    it 'handles per second threshold exception in holding availability' do
      expect { adapter.get_availability_holding(id: '9919392043506421', holding_id: '22105104420006421') }.to raise_error(Alma::PerSecondThresholdError)
    end
  end

  describe 'Alma API limit' do
    context 'when there are less requests remaining than the threshold' do
      before do
        allow(Honeybadger).to receive(:notify)
        stub_request(:get, 'https://api-na.hosted.exlibrisgroup.com/almaws/v1/bibs?expand=p_avail,e_avail,d_avail,requests&mms_id=9922486553506421')
          .with(headers: stub_alma_request_headers)
          .to_return(status: 200, body: stub_alma_per_second_threshold, headers: { 'content-Type' => 'application/json', 'x-exl-api-remaining' => (Rails.configuration.alma['api_limit'] - 1).to_s })
      end

      it 'notifies Honeybadger' do
        adapter.get_availability_one(id: '9922486553506421')
        expect(Honeybadger).to have_received :notify
      end
    end

    context 'when there are more requests remaining than the threshold' do
      before do
        allow(Honeybadger).to receive(:notify)
        stub_request(:get, 'https://api-na.hosted.exlibrisgroup.com/almaws/v1/bibs?expand=p_avail,e_avail,d_avail,requests&mms_id=9922486553506421')
          .with(headers: stub_alma_request_headers)
          .to_return(status: 200, body: stub_alma_per_second_threshold, headers: { 'content-Type' => 'application/json', 'x-exl-api-remaining' => (Rails.configuration.alma['api_limit'] + 1).to_s })
      end

      it 'does not notify Honeybadger' do
        adapter.get_availability_one(id: '9922486553506421')
        expect(Honeybadger).not_to have_received :notify
      end
    end
  end
end
