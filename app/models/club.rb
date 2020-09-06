class Club < ApplicationRecord
  belongs_to :tournament
  has_many :players

  enum status: %i[active archived]

  validates :name, uniqueness: true
  validates :code, uniqueness: true

  scope :order_by_players_count, -> { includes(:players).left_joins(:players).group(:id).order(Arel.sql('COUNT(players.id) DESC')) }

  def logo_path
    "clubs/#{path_name}.png"
  end

  def path_name
    name.downcase.tr(' ', '_')
  end
end
