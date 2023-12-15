class SlotsController < ApplicationController
  respond_to :json

  def index
    # TODO: add team_players for mantra lineups and national_players for national tournaments
    render json: { position: slots_params[:position], eurocup_players: eurocup_players }
  end

  private

  def slots_params
    params.permit(:tour_id, :position).to_unsafe_h
  end

  def eurocup_players
    return {} unless tour&.eurocup?

    players = if slots_params[:position].present?
                round_players_by_position
              else
                round_players
              end

    players.each_with_object({}) { |cp, hash| hash[cp[0].name] = cp[1].map { |item| PlayerLineupSerializer.new(item).serializable_hash } }
  end

  def round_players
    Player.includes(player_positions: :position).by_tournament_round(t_round)
          .uniq.sort_by { |x| [x.club.name] }.group_by(&:club)
  end

  def round_players_by_position
    Player.includes(player_positions: :position).by_tournament_round(t_round)
          .by_position(slots_params[:position]&.split('/'))
          .uniq.sort_by { |x| [x.club.name] }.group_by(&:club)
  end

  def t_round
    @t_round ||= tour&.tournament_round
  end

  def tour
    @tour ||= Tour.find_by(id: slots_params[:tour_id])
  end
end
