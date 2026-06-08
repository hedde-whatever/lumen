class User < ApplicationRecord
  has_secure_password validations: false

  attr_accessor :skip_password_validation

  has_many :events,              dependent: :destroy
  has_many :media,               dependent: :destroy
  has_many :refresh_tokens,      dependent: :destroy
  has_many :provider_identities, dependent: :destroy

  validates :name,  presence: true
  validates :email, presence: true,
                    uniqueness: { case_sensitive: false },
                    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password_digest, presence: true, unless: :skip_password_validation

  before_save :downcase_email

  private

  def downcase_email
    self.email = email.downcase
  end
end
