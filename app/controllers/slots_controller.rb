class SlotsController < ApplicationController
  respond_to :json

  def index
    # TODO: add team_players for mantra lineups
    render json: { position: slots_params[:position], eurocup_players: eurocup_players }
  end

  private

  def slots_params
    params.permit(:tour_id, :position).to_unsafe_h
  end

  def eurocup_players
    return {} unless tour&.eurocup?

    fanta_round_players.each_with_object({}) do |cp, hash|
      hash[cp[0].name] = cp[1].map { |item| PlayerLineupSerializer.new(item).serializable_hash }
    end
  end

  def fanta_round_players
    if tour.national?
      round_players(Player.includes(player_positions: :position).by_national_tournament_round(t_round), :national_team)
    else
      round_players(Player.includes(player_positions: :position).by_tournament_round(t_round), :club)
    end
  end

  def round_players(base_scope, group_association)
    scope = base_scope

    if (position = slots_params[:position].presence)
      scope = scope.by_position(position.split('/'))
    end

    scope = scope.includes(group_association, { club: :tournament }).distinct

    scope.sort_by(&:name)
         .group_by { |player| player.public_send(group_association) }
         .sort_by { |group, _| group.name }
  end

  def t_round
    @t_round ||= tour&.tournament_round
  end

  def tour
    @tour ||= Tour.find_by(id: slots_params[:tour_id])
  end
end
