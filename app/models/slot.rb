class Slot < ApplicationRecord
  def mantra_positions
    Position.where(name: position.split('/'))
  end
end
