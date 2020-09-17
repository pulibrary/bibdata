require 'rails_helper'

RSpec.describe PatronController, type: :controller do
  context "with an authorized ip" do
    let(:allowed_ip) { '192.168.0.1'}

    before do
     controller.request.remote_addr = allowed_ip
     allow(Rails.application.config).to receive(:ip_allowlist).and_return([allowed_ip])
   end

    it "can access patron info" do
      stub_patron('steve')
      get :patron_info, params: { patron_id: 'steve', format: :json }
      expect(response).to have_http_status(200)
    end


    it "can return patron stat codes" do
      stub_patron_codes('steve')
      get :patron_codes, params: { patron_id: 'steve', format: :json }
      expect(response).to have_http_status(200)
    end
  end

  context "with an unuathorized ip" do
    it "does not allow users that are not signed in to access patron info" do
      stub_patron('steve')
      get :patron_info, params: { patron_id: 'steve', format: :json }
      expect(response).to have_http_status(403)
    end

    it "allows authenticated users to access patron info" do
      stub_patron('steve')
      user = double('user')
      allow(request.env['warden']).to receive(:authenticate!) { user }
      allow(controller).to receive(:current_user) { user }
      get :patron_info, params: { patron_id: 'steve', format: :json }
      expect(response).to have_http_status(200)
      expect(response.body).to eq("{\"netid\":\"steve\",\"first_name\":\"Steven\",\"last_name\":\"Smith\",\"barcode\":\"00000000000000\",\"barcode_status\":1,\"barcode_status_date\":\"2013-10-17T16:11:29.000-05:00\",\"university_id\":\"000000000\",\"patron_group\":\"staff\",\"purge_date\":\"2016-10-31T23:00:06.000-05:00\",\"expire_date\":\"2017-10-31T23:00:06.000-05:00\",\"patron_id\":\"0000\",\"campus_authorized\":false}")
    end

    it "allows authenticated users to access patron info and includes campus access" do
      CampusAccess.create(uid: 'steve')
      stub_patron('steve')
      user = double('user')
      allow(request.env['warden']).to receive(:authenticate!) { user }
      allow(controller).to receive(:current_user) { user }
      get :patron_info, params: { patron_id: 'steve', format: :json }
      expect(response).to have_http_status(200)
      expect(response.body).to eq("{\"netid\":\"steve\",\"first_name\":\"Steven\",\"last_name\":\"Smith\",\"barcode\":\"00000000000000\",\"barcode_status\":1,\"barcode_status_date\":\"2013-10-17T16:11:29.000-05:00\",\"university_id\":\"000000000\",\"patron_group\":\"staff\",\"purge_date\":\"2016-10-31T23:00:06.000-05:00\",\"expire_date\":\"2017-10-31T23:00:06.000-05:00\",\"patron_id\":\"0000\",\"campus_authorized\":true}")
    end
  end

  it "retuns 404 when patron info is not found" do
    user = double('user')
    allow(request.env['warden']).to receive(:authenticate!) { user }
    allow(controller).to receive(:current_user) { user }
    allow(VoyagerHelpers::Liberator).to receive(:get_patron_info).and_return(nil)
    get :patron_info, params: { patron_id: 123456789, format: :json }
    expect(response).to have_http_status(404)
  end

end

def stub_patron(netid)
  f = File.expand_path("../../fixtures/patron-#{netid}.json",__FILE__)
  allow(VoyagerHelpers::Liberator).to receive(:get_patron_info).and_return(JSON.parse(File.read(f)))
end

def stub_patron_codes(netid)
  f = File.expand_path("../../fixtures/patron-#{netid}-codes.json",__FILE__)
  allow(VoyagerHelpers::Liberator).to receive(:get_patron_stat_codes).and_return(JSON.parse(File.read(f)))
end
