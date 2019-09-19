class Club < ApplicationRecord
  validates :name, uniqueness: true

  has_many :players

  scope :order_by_players_count, ->{ includes(:players).left_joins(:players).group(:id).order(Arel.sql('COUNT(players.id) DESC')) }

  def code
    name[0..2].upcase
  end
end
