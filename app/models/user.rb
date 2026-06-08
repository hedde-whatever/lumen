class User < ApplicationRecord
  has_many :events, dependent: :destroy
  has_many :media,  dependent: :destroy

  validates :clerk_id, presence: true, uniqueness: true
  validates :name,     presence: true
  validates :email,    presence: true,
                       uniqueness: { case_sensitive: false },
                       format: { with: URI::MailTo::EMAIL_REGEXP }

  before_save :downcase_email

  private

  def downcase_email
    self.email = email.downcase
  end
end
