FactoryBot.define do
  factory :holding_location, class: Locations::HoldingLocation do
    label 'location-label'
    aeon_location false
    recap_electronic_delivery_location false
    open true
    requestable true
    always_requestable true
    circulates true
    code 'location-code'
    library { build(:library, code: 'firestone$stacks', label: 'Firestone Library') }
  end

  factory :aeon_location, class: Locations::HoldingLocation do
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
