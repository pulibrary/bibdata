# frozen_string_literal: true

require 'rails_helper'

describe 'Holding Location views link to other associated locations' do
  let(:library) { FactoryBot.create(:library) }
  let(:delivery_location) { FactoryBot.create(:delivery_location) }
  let(:holding_location) { FactoryBot.create(:holding_location) }

  it 'Link to library from library label rather than extra show link' do
    library
    visit libraries_path
    click_link library.label
  end

  it 'Link to holding location from holding location label rather than extra show link' do
    holding_location
    visit holding_locations_path
    click_link holding_location.code
  end

  it 'Link to delivery location from delivery location label rather than extra show link' do
    delivery_location
    visit delivery_locations_path
    click_link delivery_location.label
  end

  it 'User can link to library associated with holding location from show view' do
    visit holding_locations_path(holding_location)
    click_link holding_location.library.code
  end

  it 'User can link to library associated with delivery location from index view' do
    delivery_location
    visit delivery_locations_path
    click_link delivery_location.library.code
  end

  it 'User can link to library associated with delivery location from show view' do
    visit delivery_locations_path(delivery_location)
    click_link delivery_location.library.code
  end
end
