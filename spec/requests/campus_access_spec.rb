require 'rails_helper'

RSpec.describe 'Campus Access Requests', type: :request do
  describe "GET /campus_access.csv" do
    it "lists the users with campus access in csv format" do
      CampusAccess.create(uid: 'ABC123')
      CampusAccess.create(uid: 'def456')
      CampusAccess.create(uid: 'ghi789')

      get '/campus_access.csv'
      expect(response.body).to eq("abc123@princeton.edu\ndef456@princeton.edu\nghi789@princeton.edu\n")
    end
  end
end
