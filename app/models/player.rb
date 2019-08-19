class Player < ApplicationRecord
  has_and_belongs_to_many :positions
  belongs_to :team
  belongs_to :club

  has_many :match_players, dependent: :destroy
  has_many :lineups, through: :match_players

  scope :by_position, ->(position) { joins(:positions).where(positions: { name: position }) }
  enum status: %i[ready problematic injured disqualified]

  scope :order_by_status, -> do
    order_by = ['CASE']
    statuses.values.each_with_index do |status, index|
      order_by << "WHEN status=#{status} THEN #{index}"
    end
    order_by << 'END'
    order(order_by.join(' '))
  end

  def positions_names_string
    position_names.join(' ')
  end

  def position_names
    positions.map(&:name)
  end
end
