FactoryBot.define do
  factory :hathi_access do
    oclc_number "1234567"
    bibid "100"
    status "DENY"
    origin "CUL"
  end
end
