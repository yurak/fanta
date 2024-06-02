class PlayerPosition < ApplicationRecord
  audited associated_with: :player

  belongs_to :position
  belongs_to :player

  default_scope { includes(:position) }
end
