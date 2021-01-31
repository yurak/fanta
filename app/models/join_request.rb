class JoinRequest < ApplicationRecord
  enum status: %i[initial processed archived]

  validates :username, presence: true
  validates :contact, presence: true
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
end
