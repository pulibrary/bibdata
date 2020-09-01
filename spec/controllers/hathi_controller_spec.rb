require 'rails_helper'
require 'json'

RSpec.describe HathiController, type: :controller do
  before do
     FactoryBot.create(:hathi_access)
     FactoryBot.create(:hathi_access, status: "ALLOW", oclc_number: "2243200" )
  end

  describe '#hathi_access_bib_status' do
    context 'when a bibid is provided' do
      context 'when the bib exists' do
        let(:bib_id) { "100" }
        it 'returns an array of records with the same bib' do
          get :hathi_access_bib_status, params: { bib_id: bib_id }

          expect(JSON.parse(response.body).count).to eq 2
          expect(JSON.parse(response.body)[0]["oclc_number"]).to eq("1234567")
          expect(JSON.parse(response.body)[0]["bibid"]).to eq("100")
          expect(JSON.parse(response.body)[0]["status"]).to eq("DENY")
          expect(JSON.parse(response.body)[0]["origin"]).to eq("CUL")
          expect(JSON.parse(response.body)[1]["oclc_number"]).to eq("2243200")
          expect(JSON.parse(response.body)[1]["bibid"]).to eq("100")
          expect(JSON.parse(response.body)[1]["status"]).to eq("ALLOW")
          expect(JSON.parse(response.body)[1]["origin"]).to eq("CUL")
          expect(response.status).to eq(200)
        end
      end
      context 'when the bib does not exist' do
        let(:bib_id) { "200" }
        it 'returns an empty string' do
          expect(response.body).to eq("")
        end
      end
    end
  end
end
