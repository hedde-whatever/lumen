FactoryBot.define do
  factory :medium do
    association :user
    association :event
  end
end
