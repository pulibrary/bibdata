require 'rails_helper'
require 'json'

RSpec.describe HathiController, type: :controller do
  before do
     FactoryBot.create(:hathi_access)
     FactoryBot.create(:hathi_access, status: "ALLOW", oclc_number: "2243200" )
     FactoryBot.create(:hathi_access, status: "DENY", oclc_number: "2243109", bibid: "1000", origin: "CUL" )
     FactoryBot.create(:hathi_access, status: "ALLOW", oclc_number: "2243109", bibid: "1000", origin: "CUL" )
  end

  # ToDo Remove this test when the old route hathi#hathi_access_bib_status will be removed
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

  describe '#hathi_access' do
    context 'when a bibid is provided' do
      context 'when the bib exists' do
        let(:bib_id) { "100" }
        it 'returns an array of records with the same bib' do
          get :hathi_access, params: { bib_id: bib_id }

          expect(JSON.parse(response.body).count).to eq 2
          expect(JSON.parse(response.body)[0]["oclc_number"]).to eq("1234567")
          expect(JSON.parse(response.body)[0]["bibid"]).to eq("100")
          expect(JSON.parse(response.body)[0]["status"]).to eq("DENY")
          expect(JSON.parse(response.body)[0]["origin"]).to eq("CUL")
          expect(JSON.parse(response.body)[1]["oclc_number"]).to eq("2243200")
          expect(JSON.parse(response.body)[1]["bibid"]).to eq("100")
          expect(JSON.parse(response.body)[1]["status"]).to eq("ALLOW")
          expect(JSON.parse(response.body)[1]["origin"]).to eq("CUL")
          expect(JSON.parse(response.body)[0]["id"]).to be_falsey
          expect(JSON.parse(response.body)[0]["created_at"]).to be_falsey
          expect(JSON.parse(response.body)[0]["updated_at"]).to be_falsey
          expect(response.status).to eq(200)
        end
      end
      context 'when the bib does not exist' do
        let(:bib_id) { "200" }
        it 'returns an empty array' do
          get :hathi_access, params: { bib_id: bib_id }

          expect(response.body).to eq("[]")
          expect(response.status).to eq(404)
        end
      end
    end
    context 'when an oclc is provided' do
      context 'when the oclc exists' do
        let(:oclc_number) { "2243109" }
        it 'returns an array of records with the same oclc' do
          get :hathi_access, params: { oclc: oclc_number }

          expect(JSON.parse(response.body).count).to eq 2
          expect(JSON.parse(response.body)[0]["oclc_number"]).to eq("2243109")
          expect(JSON.parse(response.body)[0]["bibid"]).to eq("1000")
          expect(JSON.parse(response.body)[0]["status"]).to eq("DENY")
          expect(JSON.parse(response.body)[0]["origin"]).to eq("CUL")
          expect(JSON.parse(response.body)[1]["oclc_number"]).to eq("2243109")
          expect(JSON.parse(response.body)[1]["bibid"]).to eq("1000")
          expect(JSON.parse(response.body)[1]["status"]).to eq("ALLOW")
          expect(JSON.parse(response.body)[1]["origin"]).to eq("CUL")
          expect(JSON.parse(response.body)[0]["id"]).to be_falsey
          expect(JSON.parse(response.body)[0]["created_at"]).to be_falsey
          expect(JSON.parse(response.body)[0]["updated_at"]).to be_falsey
          expect(response.status).to eq(200)
        end
      end
      context 'when the oclc does not exist' do
        let(:oclc_number) { "200" }
        it 'returns an empty array' do
          get :hathi_access, params: { oclc: oclc_number }

          expect(response.body).to eq("[]")
          expect(response.status).to eq(404)
          expect(response.status).not_to eq(200)
        end
      end
    end
  end
end
