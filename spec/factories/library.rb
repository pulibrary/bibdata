FactoryBot.define do
  factory :library, class: 'Library' do
    label 'Firestone Library Stacks'
    code { 'firestone$' + Faker::Alphanumeric.alphanumeric(number: 3, min_alpha: 3) }
    order { rand(0..10) }
  end
end
