# Row payload for the React round players stats page. Receives context via
# instance_options: :league_id, :national, :fanta, :deadlined.
class RoundPlayerStatsSerializer < ActiveModel::Serializer
  attributes :id
  attributes :player_id
  attributes :name
  attributes :first_name
  attributes :avatar_path
  attributes :kit_path
  attributes :position_classic_arr
  attributes :position_ital_arr
  attributes :club
  attributes :base_score
  attributes :result_score
  attributes :appearances
  attributes :main_appearances
  attributes :nationality

  def avatar_path
    object.player.avatar_path
  end

  def kit_path
    instance_options[:national] ? object.player.national_kit_path : object.player.kit_path
  end

  def position_classic_arr
    positions.map { |position| Slot::POS_MAPPING[position.name] }
  end

  def position_ital_arr
    positions.map(&:name)
  end

  def club
    ClubSerializer.new(object.related_club)
  end

  def base_score
    object.score
  end

  delegate :result_score, to: :object

  def appearances
    return unless appearances?

    object.match_players.size
  end

  def main_appearances
    return unless appearances?

    object.match_players.count(&:real_position)
  end

  def nationality
    return unless instance_options[:national]

    object.player.nationality
  end

  private

  def appearances?
    instance_options[:fanta] && instance_options[:deadlined]
  end

  def positions
    @positions ||= object.positions
  end
end
