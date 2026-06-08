FactoryBot.define do
  factory :user do
    clerk_id { "user_#{SecureRandom.hex(8)}" }
    name     { Faker::Name.name }
    email    { Faker::Internet.unique.email }
  end
end
