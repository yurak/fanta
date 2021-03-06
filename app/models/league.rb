class League < ApplicationRecord
  belongs_to :tournament
  belongs_to :season

  has_many :teams, dependent: :destroy
  has_many :tours, dependent: :destroy
  has_many :results, dependent: :destroy

  enum status: { initial: 0, active: 1, archived: 2 }

  validates :name, presence: true, uniqueness: true

  scope :by_tournament, ->(tournament_id) { where(tournament: tournament_id) }

  def active_tour
    tours&.active&.first || tours.inactive&.first
  end

  def active_tour_or_last
    active_tour || tours.last
  end

  def leader
    result = results.find { |r| r.position == 1 }
    result&.team
  end

  def self.counters(leagues)
    counters = {}
    counters['All leagues'] = leagues&.count

    if counters['All leagues']&.positive?
      Tournament.all.find_each do |t|
        counter = leagues.by_tournament(t.id).count
        counters[t.name] = counter if counter.positive?
      end
    end

    counters
  end
end
