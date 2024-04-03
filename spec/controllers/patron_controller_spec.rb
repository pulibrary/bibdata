require 'rails_helper'

RSpec.describe PatronController, type: :controller do
  context "with an authorized ip" do
    let(:allowed_ip) { '192.168.0.1' }

    before do
      controller.request.remote_addr = allowed_ip
      allow(Rails.application.config).to receive(:ip_allowlist).and_return([allowed_ip])
    end

    it "can access patron info" do
      stub_patron
      get :patron_info, params: { patron_id: 'bbird', format: :json }
      expect(response).to have_http_status(200)
    end
  end

  context "with an unauthorized ip" do
    it "does not allow users that are not signed in to access patron info" do
      stub_patron
      get :patron_info, params: { patron_id: 'bbird', format: :json }
      expect(response).to have_http_status(403)
    end

    it "does not allow non-admin users to access patron info" do
      stub_patron
      user = FactoryBot.create(:user)
      allow(request.env['warden']).to receive(:authenticate!) { user }
      allow(controller).to receive(:current_user) { user }
      get :patron_info, params: { patron_id: 'bbird', format: :json }
      expect(response).to have_http_status(403)
    end

    it "allows authenticated admin users to access patron info" do
      stub_patron
      user = FactoryBot.create(:admin)
      allow(request.env['warden']).to receive(:authenticate!) { user }
      allow(controller).to receive(:current_user) { user }
      get :patron_info, params: { patron_id: 'bbird', format: :json }
      expect(response).to have_http_status(200)
    end
  end

  describe "patron_info endpoint" do
    let(:patron_identifier) { 'bbird' }

    before do
      stub_patron(patron_identifier)
      user = FactoryBot.create(:admin)
      allow(request.env['warden']).to receive(:authenticate!) { user }
      allow(controller).to receive(:current_user) { user }
    end
    context 'authenticated users' do
      let(:patron_identifier) { 'cmonster' }

      it "allows them to access patron info" do
        get :patron_info, params: { patron_id: patron_identifier, format: :json }
        expect(response).to have_http_status(200)
        expect(JSON.parse(response.body)).to eq(
          "netid" => "cmonster",
          "first_name" => "Cookie",
          "last_name" => "Monster",
          "barcode" => "00000000000000",
          "university_id" => "100000000",
          "patron_id" => "100000000",
          "patron_group" => "UGRD",
          "patron_group_desc" => "UGRD Undergraduate",
          "campus_authorized" => false,
          "campus_authorized_category" => "none",
          "active_email" => "cmonster@SCRUBBED_Princeton.EDU"
        )
      end
    end

    it "converts patron group to 'staff'" do
      get :patron_info, params: { patron_id: patron_identifier, format: :json }
      expect(response).to have_http_status(200)
      expect(JSON.parse(response.body)["patron_group"]).to eq "staff"
    end

    it "allows authenticated users to access just patron info when desired" do
      get :patron_info, params: { patron_id: patron_identifier, format: :json }
      expect(response).to have_http_status(200)
      expect(JSON.parse(response.body)).to eq(
        "netid" => "bbird",
        "first_name" => "Big",
        "last_name" => "Bird",
        "barcode" => "00000000000000",
        "university_id" => "100000000",
        "patron_id" => "100000000",
        "patron_group" => "staff",
        "patron_group_desc" => "P Faculty & Professional",
        "campus_authorized" => false,
        "campus_authorized_category" => "none",
        "active_email" => "bbird@SCRUBBED_princeton.edu"
      )
    end

    it "allows authenticated users to access patron info and includes campus access" do
      CampusAccess.create(uid: patron_identifier)
      get :patron_info, params: { patron_id: patron_identifier, format: :json }
      expect(response).to have_http_status(200)
      expect(JSON.parse(response.body)).to eq(
        "netid" => "bbird",
        "first_name" => "Big",
        "last_name" => "Bird",
        "barcode" => "00000000000000",
        "university_id" => "100000000",
        "patron_id" => "100000000",
        "patron_group" => "staff",
        "patron_group_desc" => "P Faculty & Professional",
        "campus_authorized" => true,
        "campus_authorized_category" => "full",
        "active_email" => "bbird@SCRUBBED_princeton.edu"
      )
    end

    context 'with an unknown patron' do
      let(:patron_identifier) { "ogrouch" }

      it "returns 404 when patron info is not found" do
        stub_patron(patron_identifier, 400)
        get :patron_info, params: { patron_id: patron_identifier, format: :json }
        expect(response).to have_http_status(404)
      end
    end
    context 'using a barcode as identifier' do
      let(:patron_identifier) { '22999000883100' }

      it "allows patrons with valid barcode and without a netid" do
        barcode = patron_identifier
        get :patron_info, params: { patron_id: patron_identifier, format: :json }
        expect(response).to have_http_status(200)
        expect(JSON.parse(response.body)["barcode"]).to eq barcode
      end
    end

    context 'with an affiliate with multiple barcodes' do
      let(:patron_identifier) { 'BC123456789' }

      it 'only returns the active barcode' do
        get :patron_info, params: { patron_id: patron_identifier, format: :json }

        expect(response).to have_http_status(200)
        active_barcode = '77777777'
        expect(JSON.parse(response.body)["barcode"]).to eq active_barcode
        expect(JSON.parse(response.body)).to eq({ "netid" => nil, "first_name" => "Amir", "last_name" => "Abadi",
                                                  "barcode" => "77777777", "university_id" => "BC123456789", "patron_id" => "BC123456789",
                                                  "patron_group" => "GST", "patron_group_desc" => "GST Guest Patron",
                                                  "active_email" => "Abadi@other_school.edu",
                                                  "campus_authorized" => false, "campus_authorized_category" => "none" })
      end
    end
  end

  context "When Alma returns PER_THRESHOLD errors" do
    it "returns HTTP 429" do
      stub_request(:get, "https://api-na.hosted.exlibrisgroup.com/almaws/v1/users/bbird")
        .to_return(status: 429,
                   headers: { "Content-Type" => "application/json" },
                   body: stub_alma_per_second_threshold)
      user = FactoryBot.create(:admin)
      allow(request.env['warden']).to receive(:authenticate!) { user }
      allow(controller).to receive(:current_user) { user }

      get :patron_info, params: { patron_id: 'bbird', format: :json }
      expect(response).to have_http_status(429)
    end
  end
end

def stub_patron(netid = "bbird", status = 200)
  alma_path = Pathname.new(file_fixture_path).join("alma", "patrons")
  stub_request(:get, /.*\.exlibrisgroup\.com\/almaws\/v1\/users\/#{netid}/)
    .to_return(status:,
               headers: { "Content-Type" => "application/json" },
               body: alma_path.join("#{netid}.json"))
end
