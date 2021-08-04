# frozen_string_literal: true

require 'faker'

FactoryBot.define do
  factory :holding_location, class: 'HoldingLocation' do
    label { Faker::Company.name + ' Library' }
    aeon_location false
    recap_electronic_delivery_location false
    open true
    requestable true
    always_requestable true
    circulates true
    code { 'location-code-' + Faker::Alphanumeric.alphanumeric(number: 3, min_alpha: 3) }
    remote_storage 'recap_rmt'
    library { build(:library, label: 'Firestone Library') }
  end

  factory :holding_location_locator, class: 'HoldingLocation' do
    ignore do
      library_args nil
      hours_locations_args nil
    end
    label { 'Firestone Library' }
    aeon_location [true, false].sample
    recap_electronic_delivery_location [true, false].sample
    open [true, false].sample
    requestable [true, false].sample
    always_requestable [true, false].sample
    circulates [true, false].sample
    code 'f'
    library { build(:library, library_args) }
    remote_storage
    hours_location { build(:hours_location, hours_locations_args) }
  end

  factory :holding_location_title_locations, class: 'HoldingLocation' do
    ignore do
      library_args nil
    end
    label { 'Lewis Library' }
    aeon_location false
    recap_electronic_delivery_location false
    open true
    requestable false
    always_requestable false
    circulates true
    code 'sciss'
    library { build(:library, library_args) }
    remote_storage
  end

  factory :aeon_location, class: HoldingLocation do
    label 'location-label'
    aeon_location true
    recap_electronic_delivery_location false
    open true
    requestable true
    always_requestable true
    circulates true
    code 'location-code'
    library { build(:library, code: 'rare$jrare', label: 'Special Collections Aeon') }
  end
end
