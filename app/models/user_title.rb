class UserTitle < ApplicationRecord
  belongs_to :user
  belongs_to :tournament, optional: true
  belongs_to :result, optional: true

  scope :with_admin_includes, -> { includes(result: %i[team league]) }

  validates :championship_number, presence: true
end
