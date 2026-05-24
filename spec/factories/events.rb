FactoryBot.define do
  factory :event do
    association :user
    name         { Faker::Music.band }
    date         { Faker::Date.backward(days: 365) }
    country_name { Faker::Address.country }
    country_code { Faker::Address.country_code.first(2) }
    city         { Faker::Address.city }
    full_address { Faker::Address.full_address }
    address      { Faker::Address.street_address }
    feature_type { "venue" }
    lat          { Faker::Address.latitude }
    lng          { Faker::Address.longitude }
  end
end
