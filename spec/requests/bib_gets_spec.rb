require 'rails_helper'
require 'marc'

RSpec.describe 'Bibliographic Gets', type: :request do
  context 'when the API threshold limit is exceeded' do
    let(:bib_id) do
      '430472'
    end
    let(:alma_request_url) do
      "https://api-na.hosted.exlibrisgroup.com/almaws/v1/bibs?expand=p_avail,e_avail,d_avail,requests&mms_id=#{bib_id}"
    end
    let(:alma_request_content_type) do
      'application/json'
    end
    let(:alma_api_response) do
      {
        errorsExist: true,
        errorList: {
          error: [
            {
              errorCode: 'PER_SECOND_THRESHOLD',
              errorMessage: 'HTTP requests are more than allowed per second',
              trackingId: 'E01-0101190932-VOBYO-AWAE1554214409'
            }
          ]
        },
        result: nil
      }
    end
    let(:alma_response_body) do
      alma_api_response.to_json
    end
    let(:alma_response_headers) do
      { 'Content-Type' => 'application/json' }
    end

    before do
      stub_request(
        :get, alma_request_url
      ).to_return(
        status: 429,
        headers: alma_response_headers,
        body: alma_response_body
      )

      stub_request(:get, 'https://api-na.hosted.exlibrisgroup.com/almaws/v1/bibs?expand=p_avail,e_avail,d_avail,requests&mms_id=9922486553506421')
        .to_return(status: 429, headers: alma_response_headers, body: alma_response_body)

      stub_request(:get, 'https://api-na.hosted.exlibrisgroup.com/almaws/v1/bibs?expand=p_avail,e_avail,d_avail,requests&mms_id=9922486553506421,99122426947506421')
        .to_return(status: 429, headers: alma_response_headers, body: alma_response_body)

      stub_request(:get, 'https://api-na.hosted.exlibrisgroup.com/almaws/v1/bibs?expand=p_avail,e_avail,d_avail,requests&mms_id=9922486553506421,99122426947506421')
        .to_return(status: 429, headers: alma_response_headers, body: alma_response_body)

      stub_alma_ids(ids: '9919392043506421', status: 200)
      stub_request(:get, 'https://api-na.hosted.exlibrisgroup.com/almaws/v1/bibs/9919392043506421/holdings/22105104420006421/items?limit=100&order_by=enum_a')
        .to_return(status: 429, headers: alma_response_headers, body: alma_response_body)
    end

    describe 'GET /bibliographic/430472/items' do
      let(:alma_request_url) do
        'https://api-na.hosted.exlibrisgroup.com/almaws/v1/bibs/430472/holdings/ALL/items?direction=asc&expand=due_date_policy,due_date&limit=100&order_by=library'
      end
      let(:alma_response_headers) do
        {
          'Content-Type': 'application/json'
        }
      end

      it 'responds with a not found message to the client' do
        get '/bibliographic/430472/items'

        # This is due to an error (Alma::BibItemSet::ResponseError) which is raised within Alma::BibItemSet#validate without the data needed to parse the HTTP response
        expect(response.status).to eq(404)
      end
    end

    describe 'GET /bibliographic/430472/holdings' do
      let(:alma_request_url) do
        'https://alma/almaws/v1/bibs/430472/holdings?apikey=TESTME'
      end

      it 'responds with an error message to the client' do
        get '/bibliographic/430472/holdings'

        expect(response.status).to eq(429)
      end
    end

    describe 'GET /bibliographic/430472/holdings.xml' do
      let(:alma_request_url) do
        'https://alma/almaws/v1/bibs/430472/holdings?apikey=TESTME'
      end
      let(:alma_request_content_type) do
        'application/xml'
      end

      it 'responds with an error message to the client' do
        get '/bibliographic/430472/holdings.xml'

        expect(response.status).to eq(429)
      end
    end

    describe 'GET /bibliographic/430472/holdings.json' do
      let(:alma_request_url) do
        'https://alma/almaws/v1/bibs/430472/holdings?apikey=TESTME'
      end

      it 'responds with an error message to the client' do
        get '/bibliographic/430472/holdings.json'

        expect(response.status).to eq(429)
      end
    end

    describe 'GET /bibliographic/9922486553506421/availability.json' do
      it 'responds with an error message to the client' do
        get '/bibliographic/9922486553506421/availability.json'
        expect(response.status).to eq(429)
      end
    end

    describe 'GET /bibliographic/availability.json?bib_ids=9922486553506421,99122426947506421' do
      it 'responds with an error message to the client' do
        get '/bibliographic/availability.json?bib_ids=9922486553506421,99122426947506421'
        expect(response.status).to eq(429)
      end
    end

    describe 'GET /bibliographic/9919392043506421/holdings/22105104420006421/availability' do
      it 'responds with an error message to the client' do
        get '/bibliographic/9919392043506421/holdings/22105104420006421/availability.json'
        expect(response.status).to eq(429)
      end
    end
  end

  context 'when an API call times out' do
    let(:adapter) { AlmaAdapter.new }

    before do
      allow(AlmaAdapter).to receive(:new).and_return(adapter)
      allow(adapter).to receive(:get_availability_many).and_raise(Net::ReadTimeout)
    end

    it 'Returns proper status code' do
      get '/bibliographic/availability.json?bib_ids=9918888023506421,9929723813506421,998968313506421'
      expect(response.status).to be(504)
    end
  end

  describe 'GET /bibliographic/430472/items' do
    it 'Properly encoded item records' do
      pending 'Replace with Alma'
      stub_voyager_items('430472')
      get '/bibliographic/430472/items'
      expect(response.status).to be(200)
    end
  end

  describe 'GET /bibliographic/00000000/items' do
    it 'returns an error when the bib record does not exist' do
      pending 'Replace with Alma'
      # allow(VoyagerHelpers::Liberator).to receive(:get_items_for_bib).and_return([])
      get '/bibliographic/00000000/items'
      expect(response.status).to be(404)
    end
  end

  describe 'GET /bibliographic/6815537' do
    it 'Removes bib 852 when there is no holding record' do
      pending 'Replace with Alma'
      stub_voyager('6815537')
      get '/bibliographic/6815537.json'
      bib = JSON.parse(response.body)
      has_852 = bib['fields'].any? { |f| f.has_key?('852') }
      expect(has_852).to be(false)
    end
  end

  describe 'retrieving solr json' do
    let(:ark) { 'ark:/88435/7d278t10z' }
    let(:bib_id) { '4609321' }
    let(:docs) do
      [
        {
          id: 'b65cd851-ef01-45f2-b5bd-28c6616574ca',
          internal_resource_tsim: [
            'ScannedResource'
          ],
          internal_resource_ssim: [
            'ScannedResource'
          ],
          internal_resource_tesim: [
            'ScannedResource'
          ],
          identifier_tsim: [
            ark
          ],
          identifier_ssim: [
            ark
          ],
          identifier_tesim: [
            ark
          ],
          source_metadata_identifier_tsim: [
            bib_id
          ],
          source_metadata_identifier_ssim: [
            bib_id
          ],
          source_metadata_identifier_tesim: [
            bib_id
          ]

        }
      ]
    end
    let(:pages) do
      {
        current_page: 1,
        next_page: 2,
        prev_page: nil,
        total_pages: 1,
        limit_value: 10,
        offset_value: 0,
        total_count: 1,
        first_page?: true,
        last_page?: true
      }
    end
    let(:results) do
      {
        response: {
          docs:,
          facets: [],
          pages:
        }
      }
    end

    before do
      stub_request(:get, 'https://figgy.princeton.edu/catalog.json?f%5Bidentifier_tesim%5D%5B0%5D=ark&page=1&q=&rows=1000000').to_return(status: 200, body: JSON.generate(results))
    end

    it 'retrieves solr json for a bib record' do
      pending 'Replace with Alma'
      bib_id = '1234567'
      stub_voyager('1234567')
      get "/bibliographic/#{bib_id}/solr"
      expect(response.status).to be(200)

      solr_doc = JSON.parse(response.body)
      expect(solr_doc['id']).to eq(['1234567'])
    end

    context 'with a bib record which has an ARK' do
      it 'exposes the ARK' do
        pending 'Replace with Alma'
        bib_id = '10372293'
        stub_voyager('10372293')
        get "/bibliographic/#{bib_id}/solr"
        expect(response.status).to be(200)

        solr_doc = JSON.parse(response.body)
        expect(solr_doc['id']).to eq(['10372293'])

        expect(solr_doc).to have_key('electronic_access_1display')
        electronic_access_links = solr_doc['electronic_access_1display']
        electronic_access = JSON.parse(electronic_access_links.first)
        expect(electronic_access).to include('http://arks.princeton.edu/ark:/88435/dsp015425kd270' => ['arks.princeton.edu'])
      end
    end

    it 'displays an error when the bib record does not exist' do
      pending 'Replace with Alma'
      stub_voyager('00000000')
      get '/bibliographic/00000000/solr'
      expect(response.status).to be(404)
    end
  end

  describe 'GET /bibliographic/:bib_id' do
    it 'returns an error when the bib record does not exist' do
      pending 'Replace with Alma'
      stub_voyager('00000000')
      get '/bibliographic/00000000'
      expect(response.status).to be(404)
    end

    it 'returns xml' do
      pending 'Replace with Alma'
      stub_voyager('1234567')
      get '/bibliographic/1234567.xml'
      expect(response.status).to be(200)
      expect(response.content_type).to eq('application/xml')
    end
  end

  describe 'index' do
    it 'redirects to holdings' do
      get '/bibliographic?bib_id=1234567&holdings_only=1'
      expect(response).to redirect_to('/bibliographic/1234567/holdings')
    end

    it 'redirects to items' do
      get '/bibliographic?bib_id=1234567&items_only=1'
      expect(response).to redirect_to('/bibliographic/1234567/items')
    end

    it 'redirects to bib' do
      get '/bibliographic?bib_id=1234567'
      expect(response).to redirect_to('/bibliographic/1234567')
    end

    it 'returns an error when a bib id is not provided' do
      get '/bibliographic'
      expect(response.status).to be(404)
    end
  end

  describe 'holdings' do
    it 'provides json' do
      pending 'Replace with Alma'
      stub_voyager_holdings('1234567')
      get '/bibliographic/1234567/holdings.json' # XXX timeout
      expect(response.content_type).to eq('application/json')
    end

    it 'provides xml' do
      pending 'Replace with Alma'
      stub_voyager_holdings('1234567')
      get '/bibliographic/1234567/holdings.xml' # XXX timeout
      expect(response.content_type).to eq('application/xml')
    end

    it 'returns an error when the bib record does not exist' do
      pending 'Replace with Alma'
      # allow(VoyagerHelpers::Liberator).to receive(:get_holding_records).and_return []
      pending 'Replace with Alma'
      get '/bibliographic/00000000/holdings'
      expect(response.status).to be(404)
    end
  end

  describe 'GET /bibliographic/8637182' do
    it 'Removes bib 866' do
      pending 'Replace with Alma'
      stub_voyager('8637182')
      get '/bibliographic/8637182.json'
      bib = JSON.parse(response.body)
      has_866 = bib['fields'].any? { |f| f.has_key?('866') }
      expect(has_866).to be(false)
    end
  end

  describe '#get_catalog_date added to 959' do
    it 'adds item create_date when bib has associated items' do
      pending 'Replace with Alma'
      stub_voyager('4461315')
      get '/bibliographic/4461315.json'
      bib = JSON.parse(response.body)
      has_959 = bib['fields'].any? { |f| f.has_key?('959') }
      expect(has_959).to be(true)
    end

    it 'adds item create_date when bib without items is an elf' do
      pending 'Replace with Alma'
      stub_voyager('491668')
      get '/bibliographic/491668.json'
      bib = JSON.parse(response.body)
      has_959 = bib['fields'].any? { |f| f.has_key?('959') }
      expect(has_959).to be(true)
    end

    it 'does not add item create_date when bib without items is not elf' do
      pending 'Replace with Alma'
      stub_voyager('4609321')
      get '/bibliographic/4609321.json'
      bib = JSON.parse(response.body)
      has_959 = bib['fields'].any? { |f| f.has_key?('959') }
      expect(has_959).to be(false)
    end
  end

  describe 'holding record info is coupled with holding id in bib record' do
    it 'merges 852s and 856s from holding record into bib record' do
      pending 'Replace with Alma'
      bib_id = '7617477'
      stub_voyager('7617477')
      get "/bibliographic/#{bib_id}.json"
      ipad_bib_record = JSON.parse(response.body)

      %w[7429805 7429809 7429811].each do |id|
        stub_voyager_holding(id)
        get "/holdings/#{id}.json"
        holding = JSON.parse(response.body)
        holding = MARC::Record.new_from_hash(holding)
        eight52 = holding['852'].to_hash
        eight52['852']['subfields'].prepend('0' => id.to_s)
        eight56 = holding['856'].to_hash
        eight56['856']['subfields'].prepend('0' => id.to_s)
        expect(ipad_bib_record['fields']).to include(eight52)
        expect(ipad_bib_record['fields']).to include(eight56)
      end
    end

    it 'merges 866s from holding record into bib record when present' do
      pending 'Replace with Alma'
      bib_id = '4609321'
      stub_voyager('4609321')
      get "/bibliographic/#{bib_id}.json"
      ipad_bib_record = JSON.parse(response.body)

      %w[4847980 4848993].each do |id|
        stub_voyager_holding(id)
        get "/holdings/#{id}.json"
        holding = JSON.parse(response.body)
        holding = MARC::Record.new_from_hash(holding)
        eight66 = holding['866'].to_hash
        eight66['866']['subfields'].prepend('0' => id.to_s)
        expect(ipad_bib_record['fields']).to include(eight66)
      end
    end
  end
end

def stub_voyager(bibid)
  f = File.expand_path("../../fixtures/#{bibid}.mrx", __FILE__)
  # allow(VoyagerHelpers::Liberator).to receive(:get_bib_record).and_return MARC::XMLReader.new(f).first
end

def stub_voyager_holding(bibid)
  f = File.expand_path("../../fixtures/#{bibid}-holding.xml", __FILE__)
  # allow(VoyagerHelpers::Liberator).to receive(:get_holding_record).and_return MARC::XMLReader.new(f).first
end

def stub_voyager_holdings(bibid)
  f = File.expand_path("../../fixtures/#{bibid}-holdings.xml", __FILE__)
  # allow(VoyagerHelpers::Liberator).to receive(:get_holding_records).and_return [MARC::XMLReader.new(f).first]
end

def stub_voyager_items(bibid)
  f = File.expand_path("../../fixtures/#{bibid}-items.json", __FILE__)
  # allow(VoyagerHelpers::Liberator).to receive(:get_items_for_bib).and_return JSON.parse(File.read(f))
end
