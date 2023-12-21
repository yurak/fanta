class PlayerCurrentSeasonStatSerializer < ActiveModel::Serializer
  attributes :assists
  attributes :base_score
  attributes :caught_penalty
  attributes :cleansheet
  attributes :conceded_penalty
  attributes :failed_penalty
  attributes :goals
  attributes :missed_goals
  attributes :missed_penalty
  attributes :own_goals
  attributes :penalties_won
  attributes :played_matches
  attributes :played_minutes
  attributes :red_card
  attributes :saves
  attributes :scored_penalty
  attributes :total_score
  attributes :yellow_card

  def assists
    object.season_bonus_count(matches, 'assists')
  end

  def base_score
    object.season_average_score(matches)
  end

  def caught_penalty
    object.season_bonus_count(matches, 'caught_penalty')
  end

  def cleansheet
    object.season_cards_count(matches, 'cleansheet')
  end

  def conceded_penalty
    object.season_bonus_count(matches, 'conceded_penalty')
  end

  def failed_penalty
    object.season_bonus_count(matches, 'failed_penalty')
  end

  def goals
    object.season_bonus_count(matches, 'goals')
  end

  def missed_goals
    object.season_bonus_count(matches, 'missed_goals')
  end

  def missed_penalty
    object.season_bonus_count(matches, 'missed_penalty')
  end

  def own_goals
    object.season_bonus_count(matches, 'own_goals')
  end

  def penalties_won
    object.season_bonus_count(matches, 'penalties_won')
  end

  def played_matches
    object.season_scores_count(matches)
  end

  def played_minutes
    object.season_bonus_count(matches, 'played_minutes')
  end

  def red_card
    object.season_cards_count(matches, 'red_card')
  end

  def saves
    object.season_bonus_count(matches, 'saves')
  end

  def scored_penalty
    object.season_bonus_count(matches, 'scored_penalty')
  end

  def total_score
    object.season_average_result_score(matches)
  end

  def yellow_card
    object.season_cards_count(matches, 'yellow_card')
  end

  private

  def matches
    instance_options[:matches]
  end
end
