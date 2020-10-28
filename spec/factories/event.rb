FactoryBot.define do
  factory :event do
    start Time.now
    finish Time.now + 3600
    error nil
    success true
    created_at { finish }
    updated_at { finish }
  end
end
