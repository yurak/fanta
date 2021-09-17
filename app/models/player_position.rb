class PlayerPosition < ApplicationRecord
  belongs_to :position
  belongs_to :player

  default_scope { includes(:position) }
end
