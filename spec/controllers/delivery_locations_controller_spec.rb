# frozen_string_literal: true

require 'rails_helper'

describe DeliveryLocationsController, type: :controller do
  let(:invalid_attributes) do
    FactoryBot.attributes_for(:delivery_location, label: nil)
  end

  describe 'GET #index' do
    render_views

    it 'assigns all delivery_locations as @delivery_locations' do
      delivery_location = FactoryBot.create(:delivery_location)
      get :index
      expect(assigns(:delivery_locations)).to eq([delivery_location])
    end

    it 'delivery_locations is active in navbar' do
      get :index
      expect(response.body.include?('<li class="active"><a href="/locations/delivery_locations')).to be true
    end
  end

  describe 'GET #digital_locations' do
    render_views

    it 'assigns only digital locations as @delivery_locations' do
      digital_location = FactoryBot.create(:delivery_location, digital_location: true)
      analog_location = FactoryBot.create(:delivery_location, digital_location: false)
      get :digital_locations
      expect(assigns(:delivery_locations)).to eq([digital_location])
    end
  end

  describe 'GET #show' do
    it 'assigns the requested delivery_location as @delivery_location' do
      delivery_location = FactoryBot.create(:delivery_location)
      get :show, params: { id: delivery_location.to_param }
      expect(assigns(:delivery_location)).to eq(delivery_location)
    end
  end
end
