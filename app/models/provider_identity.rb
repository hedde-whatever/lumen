class ProviderIdentity < ApplicationRecord
  PROVIDERS = %w[google].freeze

  belongs_to :user

  validates :provider, inclusion: { in: PROVIDERS }
  validates :uid, presence: true, uniqueness: { scope: :provider }
end
