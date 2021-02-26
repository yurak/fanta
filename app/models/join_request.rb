class JoinRequest < ApplicationRecord
  enum status: { initial: 0, processed: 1, archived: 2 }

  validates :username, presence: true
  validates :contact, presence: true
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
end
