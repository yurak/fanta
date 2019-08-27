class Tour < ApplicationRecord
  enum status: %i[inactive set_lineup locked closed]

  has_many :matches, dependent: :destroy
  has_many :lineups, dependent: :destroy

  def next_number
    number + 1
  end
end
