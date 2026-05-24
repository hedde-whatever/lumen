FactoryBot.define do
  factory :medium do
    association :user
    association :event
    path { "uploads/users/#{user.id}/events/#{event.id}/#{SecureRandom.uuid}-photo.jpg" }
  end
end
