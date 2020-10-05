FactoryBot.define do
  factory :event do
    start Time.now
    finish Time.now + 180
    success true
  end
end
