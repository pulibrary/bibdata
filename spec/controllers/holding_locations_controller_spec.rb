# frozen_string_literal: true

require 'rails_helper'

describe HoldingLocationsController, type: :controller do
  let(:invalid_attributes) do
    attributes_for(:holding_location, code: nil)
  end

  describe 'GET #index' do
    render_views

    it 'assigns all holding_locations as @holding_locations' do
      holding_location = create(:holding_location)
      get :index
      expect(assigns(:holding_locations)).to eq([holding_location])
    end

    it 'holding_locations is active in navbar' do
      get :index
      expect(response.body.include?('<li class="active"><a href="/locations/holding_locations')).to be true
    end
  end

  describe 'GET #show' do
    it 'assigns the requested holding_location as @holding_location' do
      holding_location = create(:holding_location)
      get :show, params: { id: holding_location.code }
      expect(assigns(:holding_location)).to eq(holding_location)
    end
  end
end
