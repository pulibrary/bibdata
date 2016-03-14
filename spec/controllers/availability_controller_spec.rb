require 'rails_helper'
require 'json'

RSpec.describe AvailabilityController, :type => :controller do

  describe 'bib availability hash' do
    it 'provides availability for only the first 2 holdings by default' do
      allow(VoyagerHelpers::Liberator).to receive(:get_availability).and_return({"929437"=>{"1068356"=>{:more_items=>false, :location=>"rcppa", :status=>"Not Charged"}, "1068357"=>{:more_items=>false, :location=>"fnc", :status=>"Not Charged"}}})
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
      allow(VoyagerHelpers::Liberator).to receive(:get_availability).and_return({"1068356"=>{:more_items=>false, :location=>"rcppa", :status=>"Not Charged"}, "1068357"=>{:more_items=>false, :location=>"fnc", :status=>"Not Charged"}, "1068358"=>{:more_items=>false, :location=>"anxb", :status=>"Not Charged"}})
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
    let(:lib_loc) { Locations::Library.new(label: 'Library')}
    let(:holding_loc) { Locations::HoldingLocation.new(circulates: false, library: lib_loc, label: '')}
    let(:holding_loc_label) { Locations::HoldingLocation.new(circulates: false, label: 'Special Room', library: lib_loc)}
    it 'voyager status is returned for item' do
      allow(VoyagerHelpers::Liberator).to receive(:get_availability).and_return({"35345"=>{"39176"=>{:more_items=>false, :location=>"f", :status=>"Not Charged"}}})
      bib_with_item = '35345'
      holding_id = '39176'
      item_id = 36736
      get :index, ids: [bib_with_item], format: :json
      availability = JSON.parse(response.body)
      expect(availability[bib_with_item][holding_id]['status']).to eq('Not Charged')
    end

    it 'elf records have a status of online' do
      allow(VoyagerHelpers::Liberator).to receive(:get_availability).and_return({"7916044"=>{"7698138"=>{:more_items=>false, :location=>"elf1", :status=>"Online"}, "7860428"=>{:more_items=>false, :location=>"rcpph", :status=>"Not Charged"}}})
      bib_online = '7916044'
      holding_id = '7698138'
      get :index, ids: [bib_online], format: :json
      availability = JSON.parse(response.body)
      expect(availability[bib_online][holding_id]['location']).to eq('elf1')
      expect(availability[bib_online][holding_id]['status']).to eq('Online')
    end

    it 'on-order records have a status of On-Order' do
      allow(VoyagerHelpers::Liberator).to receive(:get_availability).and_return({"9173362"=>{"9051785"=>{:more_items=>false, :location=>"f", :status=>"On-Order 09-10-2015"}}})
      bib_on_order = '9173362'
      holding_id = '9051785'
      get :index, ids: [bib_on_order], format: :json
      availability = JSON.parse(response.body)
      expect(availability[bib_on_order][holding_id]['status']).to include('On-Order')
    end

    it 'limited access location on-order records have a status of On-Order' do
      allow(VoyagerHelpers::Liberator).to receive(:get_item_ids_for_holding).and_return([])
      allow(VoyagerHelpers::Liberator).to receive(:get_order_status).and_return('On-Order')
      allow(VoyagerHelpers::Liberator).to receive(:get_availability).and_return({"9355531"=>{:more_items=>false, :location=>"sa", :status=>"On-Order"}})
      marquand = '9497429'
      get :index, id: marquand, format: :json
      availability = JSON.parse(response.body)
      key, value = availability.first
      expect(value['location']).to eq('sa')
      expect(value['status']).to include('On-Order')
    end

    it 'online on-order records have a status of On-Order' do
      allow(VoyagerHelpers::Liberator).to receive(:get_order_status).and_return('On-Order')
      allow(VoyagerHelpers::Liberator).to receive(:get_availability).and_return({"9096471"=>{:more_items=>false, :location=>"elf1", :status=>"On-Order"}})
      online = '9226664'
      get :index, id: online, format: :json
      availability = JSON.parse(response.body)
      key, value = availability.first
      expect(value['location']).to include('elf')
      expect(value['status']).to include('On-Order')
    end

    it 'Received on-order records have a status of Order Received' do
      allow(VoyagerHelpers::Liberator).to receive(:get_availability).and_return({"9329199"=>{:more_items=>false, :location=>"f", :status=>"Order Received 12-16-2015"}})
      bib_received_order = '9468468'
      get :index, id: bib_received_order, format: :json
      availability = JSON.parse(response.body)
      expect(availability.first[1]['status']).to include('Order Received')
    end

    it 'non_circulating locations have a status of limited' do
      allow_any_instance_of(described_class).to receive(:get_holding_location).and_return(holding_loc)
      allow(VoyagerHelpers::Liberator).to receive(:get_availability).and_return({"4609321"=>{"4847980"=>{:more_items=>false, :location=>"whs", :status=>"On Shelf"}, "4848993"=>{:more_items=>false, :location=>"whs", :status=>"Limited"}}})
      bible = '4609321'
      holding_id = '4847980'
      get :index, ids: [bible], format: :json
      availability = JSON.parse(response.body)
      expect(availability[bible][holding_id]['status']).to eq('Limited')
    end

    it 'Items with temp location codes are mapped the display value' do
      allow_any_instance_of(described_class).to receive(:get_holding_location).and_return(holding_loc_label)
      allow(VoyagerHelpers::Liberator).to receive(:get_availability).and_return({"9329199"=>{:more_items=>false, :location=>"f", :on_reserve=>'woooo', :status=>"Charged"}})
      bib_received_order = '9468468'
      get :index, id: bib_received_order, format: :json
      availability = JSON.parse(response.body)
      expect(availability.first[1]['on_reserve']).to include(holding_loc_label.label, holding_loc_label.library.label)
    end

    it 'temp location codes with no holding locl label display on library name' do
      allow_any_instance_of(described_class).to receive(:get_holding_location).and_return(holding_loc)
      allow(VoyagerHelpers::Liberator).to receive(:get_availability).and_return({"9329199"=>{:more_items=>false, :location=>"f", :on_reserve=>'woooo', :status=>"Charged"}})
      bib_received_order = '9468468'
      get :index, id: bib_received_order, format: :json
      availability = JSON.parse(response.body)
      expect(availability.first[1]['on_reserve']).to eq(holding_loc.library.label)
    end

    it 'all other holding records without items have a status of On Shelf' do
      allow(VoyagerHelpers::Liberator).to receive(:get_availability).and_return({"7617477"=>{"7429805"=>{:more_items=>false, :location=>"f", :status=>"On Shelf"}, "7429809"=>{:more_items=>false, :location=>"sci", :status=>"On Shelf"}}})
      bib_ipad = '7617477'
      holding_id = '7429805'
      get :index, ids: [bib_ipad], format: :json
      availability = JSON.parse(response.body)
      expect(availability[bib_ipad][holding_id]['status']).to eq('On Shelf')
    end

    it 'more_items is true when there is more than 1 item for a holding' do
      allow(VoyagerHelpers::Liberator).to receive(:get_availability).and_return({"857469"=>{"977093"=>{:more_items=>true, :location=>"f", :status=>"Not Charged"}, "977094"=>{:more_items=>true, :location=>"rcppf", :status=>"Not Charged"}}})
      bib_multiple_items = '857469'
      holding_id = '977093'
      get :index, ids: [bib_multiple_items], format: :json
      availability = JSON.parse(response.body)
      expect(availability[bib_multiple_items][holding_id]['more_items']).to eq(true)
    end

    it 'more_items is false when there is 1 item or less for a holding' do
      allow(VoyagerHelpers::Liberator).to receive(:get_availability).and_return({"35345"=>{"39176"=>{:more_items=>false, :location=>"f", :status=>"Not Charged"}}})
      bib_1_item = '35345'
      holding_id = '39176'
      get :index, ids: [bib_1_item], format: :json
      availability = JSON.parse(response.body)
      expect(availability[bib_1_item][holding_id]['more_items']).to eq(false)
    end
  end

  describe 'full mfhd availability array' do
    it 'returns info for all items for a given mfhd' do
      allow(VoyagerHelpers::Liberator).to receive(:get_full_mfhd_availability).and_return([{:barcode=>"32101082329929", :id=>502918, :status=>"Not Charged", :enum=>"1994"}, {:barcode=>"32101082329937", :id=>502919, :status=>"Not Charged", :enum=>"1995"}, {:barcode=>"32101082329945", :id=>502920, :status=>"Not Charged", :enum=>"1996"}, {:barcode=>"32101035390275", :id=>502921, :status=>"Not Charged", :enum=>"1954-59"}, {:barcode=>"32101082329895", :id=>1767770, :status=>"Not Charged", :enum=>"1964"}])
      holding_id = '464473'
      get :index, mfhd: holding_id, format: :json
      availability = JSON.parse(response.body)
      expect(availability.length).to eq(5)
    end
  end

  describe 'mfhd_serial location has current' do
    it '404 when no volumes found for given mfhd' do
      allow(VoyagerHelpers::Liberator).to receive(:get_current_issues).and_return([])
      get :index, mfhd_serial: '12345678901', format: :json
      expect(response).to have_http_status(404)
    end
    it 'current volumes for given_mfhd are parsed as an array' do
      allow(VoyagerHelpers::Liberator).to receive(:get_current_issues).and_return(['v1', 'v2', 'v3'])
      get :index, mfhd_serial: '12345678901', format: :json
      current_issues = JSON.parse(response.body)
      expect(current_issues).to match_array(['v1', 'v2', 'v3'])
    end
  end

  it "404 when bibs are not provided" do
    allow(VoyagerHelpers::Liberator).to receive(:get_availability).and_return({})
    get :index, ids: [], format: :json
    expect(response).to have_http_status(404)
  end

  it "404 when records are not found" do
    allow(VoyagerHelpers::Liberator).to receive(:get_availability).and_return({})
    get :index, ids: ['12345678901'], format: :json
    expect(response).to have_http_status(404)
  end

end
