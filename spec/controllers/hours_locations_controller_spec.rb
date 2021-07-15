# frozen_string_literal: true
require 'rails_helper'

describe HoursLocationsController, type: :controller do
  let(:invalid_attributes) do
    FactoryBot.attributes_for(:hours_location, label: nil)
  end

  let(:valid_session) { {} }

  describe 'GET #index' do
    render_views

    it 'assigns all hours_locations as @hours_locations' do
      hours_location = FactoryBot.create(:hours_location)
      get :index
      expect(assigns(:hours_locations)).to eq([hours_location])
    end

    it 'hours_locations is active in navbar' do
      get :index
      expect(response.body.include?('<li class="active"><a href="/hours_locations')).to eq true
    end
  end

  describe 'GET #show' do
    it 'assigns the requested hours_location as @hours_location' do
      hours_location = FactoryBot.create(:hours_location)
      get :show, params: { id: hours_location.code }
      expect(assigns(:hours_location)).to eq(hours_location)
    end
  end
end
