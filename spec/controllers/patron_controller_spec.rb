require 'rails_helper'

RSpec.describe PatronController, type: :controller do
  context "with an authorized ip" do
    let(:whitelisted_ip) { '192.168.0.1'}
    let(:whitelisted_range) { '192.168.0.0/16'}
    let(:whitelisted_another_ip) { '192.169.0.3'}

    before do
     controller.request.remote_addr = whitelisted_ip
     allow(Rails.application.config).to receive(:ip_whitelist).and_return([whitelisted_range, whitelisted_another_ip, whitelisted_ip])
   end

    it "can access patron info" do
      stub_patron('steve')
      get :patron_info, params: { patron_id: 'steve', format: :json }
      expect(response).to have_http_status(200)
    end

    it "can access patron info with an identical match" do
      controller.request.remote_addr = whitelisted_another_ip
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
