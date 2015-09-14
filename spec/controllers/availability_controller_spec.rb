require 'rails_helper'
require 'json'

RSpec.describe AvailabilityController, :type => :controller do

  it "each bib id provided is a key in the availability hash, each id value has a more_holdings key" do
    id_params = ['123','456', '789']
    get :index, ids: id_params, format: :json
    availability = JSON.parse(response.body)
    id_params.each do |id|
      expect(availability).to include(id)
      expect(availability[id]).to include('more_holdings')
    end
  end

  it 'more_holdings is false when there are two or less holdings' do
    bib_2_holdings = '8217104'
    bib_1_holding = '35345'
    get :index, ids: [bib_2_holdings, bib_1_holding], format: :json
    availability = JSON.parse(response.body)
    expect(availability[bib_2_holdings]['more_holdings']).to eq(false)
    expect(availability[bib_1_holding]['more_holdings']).to eq(false)
  end

  it 'provides availability for only the first 2 holdings, when more_holdings is true' do
    bib_3_holdings = '929437'
    get :index, ids: [bib_3_holdings], format: :json
    availability = JSON.parse(response.body)
    expect(availability[bib_3_holdings]).to include('rcppa')
    expect(availability[bib_3_holdings]).to include('fnc')
    expect(availability[bib_3_holdings]['more_holdings']).to eq(true)
    expect(availability[bib_3_holdings]).not_to include('anxb')
  end

  it "404 when bibs are not provided" do
    get :index, ids: [], format: :json
    expect(response).to have_http_status(404)
  end

  it "404 when records are not found" do
    allow(VoyagerHelpers::Liberator).to receive(:get_availability).and_return({})
    get :index, ids: ['12345678901'], format: :json
    expect(response).to have_http_status(404)
  end

end
