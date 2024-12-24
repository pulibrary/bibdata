require 'rails_helper'

RSpec.describe 'Health Check', type: :request do
  describe 'GET /health' do
    it 'has a health check' do
      get '/health.json'
      expect(response).to be_successful
    end

    context 'when solr is down' do
      let(:solr_url) { %r{/solr/admin/cores\?action=STATUS} }

      before do
        stub_request(:get, solr_url).to_return(
          body: { responseHeader: { status: 500 } }.to_json, headers: { 'Content-Type' => 'text/json' }
        )
      end

      it 'errors' do
        get '/health.json'

        expect(response).not_to be_successful
        expect(response.status).to eq 503
        solr_response = JSON.parse(response.body)['results'].find { |x| x['name'] == 'SolrStatus' }
        expect(solr_response['message']).to start_with 'The solr has an invalid status'
      end
    end
  end
end
