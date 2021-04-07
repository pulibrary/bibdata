FactoryBot.define do
  factory :delivery_location, class: Locations::DeliveryLocation do
    label 'delivery-location-label'
    address 'delivery-address'
    phone_number '888-888-8888'
    contact_email 'example@foo.com'
    staff_only false
    gfa_pickup 'PQ'
    pickup_location true
    library { build(:library, code: 'firestone$stacks', label: 'Firestone Library') }
    digital_location true
  end
end
