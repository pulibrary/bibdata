FactoryBot.define do
  factory :user do
    sequence(:username) { "username#{srand}" }
    sequence(:email) { "email-#{srand}@princeton.edu" }
    provider 'cas'
    password 'foobarfoo'
    uid(&:username)

    factory :admin do
      uid 'admin123'
    end
  end
end
