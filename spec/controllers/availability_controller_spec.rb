require 'rails_helper'
require 'json'

RSpec.describe AvailabilityController, :type => :controller do

  describe 'bib availability hash' do
    it 'provides availability for only the first 2 holdings by default' do
      bib_3_holdings = '929437'
      get :index, ids: [bib_3_holdings], format: :json
      availability = JSON.parse(response.body)
      bib_availability = availability[bib_3_holdings]
      holding_locations = bib_availability.each_value.map { |holding| holding['location'] }
      expect(holding_locations).to include('rcppa')
      expect(holding_locations).to include('fnc')
      expect(holding_locations).not_to include('anxb')
    end

    it 'provides availability for all holdings if full availability requested' do
      bib_3_holdings = '929437'
      get :index, id: bib_3_holdings, format: :json
      availability = JSON.parse(response.body)
      holding_locations = availability.each_value.map { |holding| holding['location'] }
      expect(holding_locations).to include('rcppa')
      expect(holding_locations).to include('fnc')
      expect(holding_locations).to include('anxb')
    end
  end

  describe 'holding availability hash' do
    it 'voyager status is returned for item' do
      bib_with_item = '35345'
      holding_id = '39176'
      item_id = 36736
      item_status = VoyagerHelpers::Liberator.get_item(item_id)[:status]
      get :index, ids: [bib_with_item], format: :json
      availability = JSON.parse(response.body)
      expect(availability[bib_with_item][holding_id]['status']).to eq(item_status)
    end

    it 'elf records have a status of online' do
      bib_online = '7916044'
      holding_id = '7698138'
      get :index, ids: [bib_online], format: :json
      availability = JSON.parse(response.body)
      expect(availability[bib_online][holding_id]['location']).to eq('elf1')
      expect(availability[bib_online][holding_id]['status']).to eq('Online')
    end

    it 'on-order records have a status of requestable' do
      bib_on_order = '9160439'
      holding_id = '9040953'
      get :index, ids: [bib_on_order], format: :json
      availability = JSON.parse(response.body)
      expect(availability[bib_on_order][holding_id]['status']).to eq('Requestable')
    end

    it 'non open locations have a status of limited' do
      allow(VoyagerHelpers::Liberator).to receive(:closed_holding_location?).and_return(true)
      bible = '4609321'
      holding_id = '4847980'
      get :index, ids: [bible], format: :json
      availability = JSON.parse(response.body)
      puts availability
      expect(availability[bible][holding_id]['status']).to eq('Limited')
    end

    it 'all other holding records without items have a status of unknown' do
      bib_ipad = '7617477'
      holding_id = '7429805'
      get :index, ids: [bib_ipad], format: :json
      availability = JSON.parse(response.body)
      expect(availability[bib_ipad][holding_id]['status']).to eq('Unknown')
    end

    it 'more_items is true when there is more than 1 item for a holding' do
      bib_multiple_items = '857469'
      holding_id = '977093'
      get :index, ids: [bib_multiple_items], format: :json
      availability = JSON.parse(response.body)
      expect(availability[bib_multiple_items][holding_id]['more_items']).to eq(true)
    end

    it 'more_items is false when there is 1 item or less for a holding' do
      bib_1_item = '35345'
      holding_id = '39176'
      get :index, ids: [bib_1_item], format: :json
      availability = JSON.parse(response.body)
      expect(availability[bib_1_item][holding_id]['more_items']).to eq(false)
    end
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
