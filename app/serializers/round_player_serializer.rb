class RoundPlayerSerializer < ActiveModel::Serializer
  attributes :id
  attributes :assists
  attributes :base_score
  attributes :caught_penalty
  attributes :cleansheet
  attributes :club_id
  attributes :conceded_penalty
  attributes :failed_penalty
  attributes :goals
  attributes :missed_penalty
  attributes :missed_goals
  attributes :own_goals
  attributes :penalties_won
  attributes :played_minutes
  attributes :player_id
  attributes :red_card
  attributes :saves
  attributes :scored_penalty
  attributes :total_score
  attributes :tournament_round_id
  attributes :tournament_round_number
  attributes :yellow_card

  def base_score
    object.score
  end

  def total_score
    object.final_score
  end

  def tournament_round_number
    object.tournament_round.number
  end
end
