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
end
