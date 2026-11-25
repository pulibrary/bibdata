# frozen_string_literal: true

require 'rails_helper'

describe 'Holding Location views link to other associated locations' do
  let(:library) { create(:library) }
  let(:delivery_location) { create(:delivery_location) }
  let(:holding_location) { create(:holding_location) }
  let(:holding_location_rust) do
    delivery_location_codes = holding_location.delivery_locations.map(&:gfa_pickup)
    instance_double(
      BibdataRs::Location,
      label: "Rust #{holding_location.label}",
      code: "rust:#{holding_location.code}",
      holding_library_label: holding_location.holding_library&.label,
      remote_storage: holding_location.remote_storage,
      fulfillment_unit: holding_location.fulfillment_unit,
      aeon_location: holding_location.aeon_location,
      recap_electronic_delivery_location: holding_location.recap_electronic_delivery_location,
      open: holding_location.open,
      requestable: holding_location.requestable,
      always_requestable: holding_location.always_requestable,
      circulates: holding_location.circulates,
      delivery_location_codes: delivery_location_codes
    )
  end

  before do
    allow(BibdataRs::Location).to receive(:holding_location)
      .with(holding_location.code)
      .and_return(holding_location_rust)

    holding_location.delivery_locations.map(&:gfa_pickup).uniq.each do |gfa_pickup|
      delivery_location = holding_location.delivery_locations.find { |d| d.gfa_pickup == gfa_pickup }
      allow(BibdataRs::Location).to receive(:delivery_location)
        .with(gfa_pickup)
        .and_return(
          instance_double(
            BibdataRs::Location,
            label: delivery_location.label,
            id: delivery_location.id
          )
        )
    end
  end

  it 'Link to library from library label rather than extra show link' do
    library
    visit libraries_path
    click_link library.label
  end

  it 'Link to holding location from holding location label rather than extra show link' do
    holding_location
    visit holding_locations_path
    click_link holding_location.code
    expect(page).to have_content(holding_location_rust.label)
    expect(page).to have_content(holding_location_rust.code)
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
