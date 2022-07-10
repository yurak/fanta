class JoinRequest < ApplicationRecord
  belongs_to :user

  enum status: { initial: 0, processed: 1, archived: 2 }

  validates :leagues, presence: true
end
