require 'rails_helper'

RSpec.describe PatronController, :type => :controller do

  it "authorized ips can access patron info" do
    allow_any_instance_of(ActionDispatch::Request).to receive(:remote_ip).and_return('192.168.0.1')
    allow_any_instance_of(described_class).to receive(:load_ip_whitelist).and_return(['192.168.0.1'])    
    get :patron_info, patron_id: 'steve', format: :json
    expect(response).to have_http_status(200)
  end

  it "unuathorized ips that are not signed in cannot access patron info" do
    get :patron_info, patron_id: 'steve', format: :json
    expect(response).to have_http_status(403)
  end

  it "unuathorized ips that are authenticated can access patron info" do
    user = double('user')
    allow(request.env['warden']).to receive(:authenticate!) { user }
    allow(controller).to receive(:current_user) { user }
    get :patron_info, patron_id: 'steve', format: :json
    expect(response).to have_http_status(200)
  end

  it "404 when patron info is not found" do
    user = double('user')
    allow(request.env['warden']).to receive(:authenticate!) { user }
    allow(controller).to receive(:current_user) { user }
    get :patron_info, patron_id: 123456789, format: :json
    expect(response).to have_http_status(404)
  end

end
