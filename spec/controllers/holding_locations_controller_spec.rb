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
      nav_link = response.parsed_body
                         .at_css('li.nav-item.active a[href^="/locations/holding_locations"]')

      expect(nav_link).not_to be_nil
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
