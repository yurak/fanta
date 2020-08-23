class JoinRequest < ApplicationRecord
  validates :username, presence: true
  validates :contact, presence: true
  validates :email, presence: true

  enum status: %i[initial processed archived]
end
