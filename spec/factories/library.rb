FactoryBot.define do
  factory :library, class: 'Locations::Library' do
    label 'Firestone Library Stacks'
    code 'firestone$stacks'
    order { rand(0..10) }
  end
end
