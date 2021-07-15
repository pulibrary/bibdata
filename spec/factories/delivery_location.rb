# frozen_string_literal: true

FactoryBot.define do
  factory :delivery_location, class: 'DeliveryLocation' do
    label 'delivery-location-label'
    address 'delivery-address'
    phone_number '888-888-8888'
    contact_email 'example@foo.com'
    staff_only false
    gfa_pickup 'PQ'
    pickup_location true
    library { build(:library, label: 'Firestone Library') }
    digital_location true
  end
end
