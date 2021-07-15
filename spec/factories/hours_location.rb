# frozen_string_literal: true

require 'faker'

FactoryBot.define do
  factory :hours_location, class: 'HoursLocation' do
    label { Faker::Company.name + ' Library' }
    code { 'location-code-' + Faker::Alphanumeric.alphanumeric(number: 3, min_alpha: 3) }
  end
end
