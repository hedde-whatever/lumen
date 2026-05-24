class Event < ApplicationRecord
  belongs_to :user
  has_many   :media, dependent: :destroy

  validates :name, presence: true
  validates :lat, numericality: { allow_nil: true,
                                  greater_than_or_equal_to: -90,
                                  less_than_or_equal_to: 90 }
  validates :lng, numericality: { allow_nil: true,
                                  greater_than_or_equal_to: -180,
                                  less_than_or_equal_to: 180 }

  scope :chronological, -> { order(date: :desc) }
end
