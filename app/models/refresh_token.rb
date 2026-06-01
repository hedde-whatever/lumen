class RefreshToken < ApplicationRecord
  belongs_to :user

  EXPIRY_DAYS = 30

  before_create { self.token      = SecureRandom.hex(32) }
  before_create { self.expires_at = EXPIRY_DAYS.days.from_now }

  scope :valid, -> { where(revoked_at: nil).where("expires_at > ?", Time.current) }

  def revoke! = update!(revoked_at: Time.current)
end
