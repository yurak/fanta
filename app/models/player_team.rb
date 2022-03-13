class PlayerTeam < ApplicationRecord
  belongs_to :player
  belongs_to :team

  enum transfer_status: { untouchable: 0, transferable: 1 }

  default_scope { includes(:player) }
end
