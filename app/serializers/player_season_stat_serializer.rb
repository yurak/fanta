class PlayerSeasonStatSerializer < ActiveModel::Serializer
  attributes :id
  attributes :assists
  attributes :base_score
  attributes :caught_penalty
  attributes :cleansheet
  attributes :club_id
  attributes :club_logo_path
  attributes :conceded_penalty
  attributes :failed_penalty
  attributes :goals
  attributes :missed_goals
  attributes :missed_penalty
  attributes :own_goals
  attributes :penalties_won
  attributes :played_minutes
  attributes :played_matches
  attributes :player_id
  attributes :position_price
  attributes :position_classic_arr
  attributes :position_ital_arr
  attributes :red_card
  attributes :saves
  attributes :scored_penalty
  attributes :season
  attributes :season_id
  attributes :sixties
  attributes :total_score
  attributes :tournament_id
  attributes :yellow_card

  def base_score
    object.score
  end

  def club_logo_path
    object.club&.logo_path
  end

  def position_classic_arr
    object.position_ital_arr.map { |pos| Slot::POS_MAPPING[pos] }
  end

  def season
    SeasonSerializer.new(object.season) if object.season
  end

  def total_score
    object.final_score
  end
end
