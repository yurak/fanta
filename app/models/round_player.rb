class RoundPlayer < ApplicationRecord
  belongs_to :tournament_round
  belongs_to :player

  has_many :match_players, dependent: :destroy
  has_many :lineups, through: :match_players

  delegate :position_names, :positions, :name, :first_name, :full_name, :club, :teams, to: :player

  scope :by_tournament_round, ->(tournament_round_id) { where(tournament_round: tournament_round_id) }
  scope :by_name_and_club, ->(name, club_id) { joins(:player).where('players.name = ?', name).where('players.club_id = ?', club_id) }
  scope :with_score, -> { where('score > ?', 0) }
  scope :ordered_by_club, -> { joins(player: :club).order('clubs.name') }

  def result_score
    return 0 unless score

    total = score

    # TODO: add ability customize bonuses/maluses values
    # bonuses
    total += goals * 3 if goals
    total += caught_penalty * 3 if caught_penalty
    total += scored_penalty * 2 if scored_penalty
    total += assists if assists

    # maluses
    total -= missed_goals * 2 if missed_goals
    total -= missed_penalty if missed_penalty
    total -= failed_penalty * 3 if failed_penalty
    total -= own_goals * 2 if own_goals
    total -= 0.5 if yellow_card
    total -= 1 if red_card

    total
  end

  def player_score
    # TODO: temp method for correct data migrations
    score
  end
end
