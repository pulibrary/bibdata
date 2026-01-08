# frozen_string_literal: true

require 'faker'

FactoryBot.define do
  factory :holding_location, class: 'HoldingLocation' do
    label { Faker::Company.name + ' Library' }
    aeon_location { false }
    recap_electronic_delivery_location { false }
    open { true }
    requestable { true }
    always_requestable { true }
    circulates { true }
    code { 'location-code-' + Faker::Alphanumeric.alphanumeric(number: 3, min_alpha: 3) }
    remote_storage { 'recap_rmt' }
    fulfillment_unit { 'example_unit' }
    # rubocop:disable FactoryBot/FactoryAssociationWithStrategy
    library { build(:library, label: 'Firestone Library') }
    # rubocop:enable FactoryBot/FactoryAssociationWithStrategy
  end

  factory :holding_location_locator, class: 'HoldingLocation' do
    transient do
      library_args { nil }
    end
    label { 'Firestone Library' }
    aeon_location { [true, false].sample }
    recap_electronic_delivery_location { [true, false].sample }
    open { [true, false].sample }
    requestable { [true, false].sample }
    always_requestable { [true, false].sample }
    circulates { [true, false].sample }
    code { 'f' }
    # rubocop:disable FactoryBot/FactoryAssociationWithStrategy
    library { build(:library, library_args) }
    # rubocop:enable FactoryBot/FactoryAssociationWithStrategy
    remote_storage
  end

  factory :holding_location_title_locations, class: 'HoldingLocation' do
    transient do
      library_args { nil }
    end
    label { 'Lewis Library' }
    aeon_location { false }
    recap_electronic_delivery_location { false }
    open { true }
    requestable { false }
    always_requestable { false }
    circulates { true }
    code { 'sciss' }
    # rubocop:disable FactoryBot/FactoryAssociationWithStrategy
    library { build(:library, library_args) }
    # rubocop:enable FactoryBot/FactoryAssociationWithStrategy
    remote_storage
  end

  factory :aeon_location, class: 'HoldingLocation' do
    label { 'location-label' }
    aeon_location { true }
    recap_electronic_delivery_location { false }
    open { true }
    requestable { true }
    always_requestable { true }
    circulates { true }
    code { 'location-code' }
    # rubocop:disable FactoryBot/FactoryAssociationWithStrategy
    library { build(:library, code: 'rare$jrare', label: 'Special Collections Aeon') }
    # rubocop:enable FactoryBot/FactoryAssociationWithStrategy
  end

  factory :map_location, class: 'HoldingLocation' do
    label { 'location-label' }
    aeon_location { false }
    recap_electronic_delivery_location { false }
    open { true }
    requestable { true }
    always_requestable { true }
    circulates { false }
    code { 'location-code' }
    # rubocop:disable FactoryBot/FactoryAssociationWithStrategy
    library { build(:library, code: 'lewis$mapmc', label: 'Lewis Library - Map Collection. Map Case') }
    # rubocop:enable FactoryBot/FactoryAssociationWithStrategy
  end

  factory :special_collection_location, class: 'HoldingLocation' do
    label { 'location-label' }
    aeon_location { false }
    recap_electronic_delivery_location { false }
    open { true }
    requestable { false }
    always_requestable { false }
    circulates { true }
    code { 'location-code' }
    # rubocop:disable FactoryBot/FactoryAssociationWithStrategy
    library { build(:library, code: 'rare$scaex', label: 'Special Collections - Rare Books Archival. Special Collections Use Only"') }
    # rubocop:enable FactoryBot/FactoryAssociationWithStrategy
  end
end
