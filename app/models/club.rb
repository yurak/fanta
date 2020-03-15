class Club < ApplicationRecord
  belongs_to :tournament
  has_many :players

  validates :name, uniqueness: true
  validates :code, uniqueness: true

  scope :order_by_players_count, -> { includes(:players).left_joins(:players).group(:id).order(Arel.sql('COUNT(players.id) DESC')) }

  def code
    name[0..2].upcase
  end
end
