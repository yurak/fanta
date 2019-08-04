class Slot < ApplicationRecord
  def positions
    position.split('/')
  end
end
