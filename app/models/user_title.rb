class UserTitle < ApplicationRecord
  belongs_to :user
  belongs_to :tournament, optional: true
  belongs_to :result, optional: true

  validates :championship_number, presence: true
end
