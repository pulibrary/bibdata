# frozen_string_literal: true

require 'faker'

FactoryBot.define do
  factory :hours_location, class: HoursLocation do
    label { Faker::Company.name + ' Library' }
    code
  end
end
