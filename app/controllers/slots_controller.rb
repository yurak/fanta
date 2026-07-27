class SlotsController < ApplicationController
  respond_to :json

  def index
    render json: {
      position: slots_params[:position],
      eurocup_players: eurocup_players,
      team_players_html: team_players_html
    }
  end

  private

  def slots_params
    params.permit(:tour_id, :team_id, :team_module_id, :index, :position).to_unsafe_h
  end

  def eurocup_players
    return {} unless tour&.eurocup?

    fanta_round_players.each_with_object({}) do |cp, hash|
      hash[cp[0].name] = cp[1].map { |item| PlayerLineupSerializer.new(item).serializable_hash }
    end
  end

  def team_players_html
    return if tour.nil? || tour.eurocup? || team.nil? || team_module.nil?

    render_to_string(
      partial: 'lineups/slot_candidates',
      formats: [:html],
      locals: { team: team, tour: tour, slot: slot, index: slot_index, gk_slot: team_module.slots.first }
    )
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

  def slot_index
    @slot_index ||= slots_params[:index].to_i
  end

  def slot
    team_module.slots[slot_index]
  end

  def team
    return @team if defined?(@team)

    @team = Team.find_by(id: slots_params[:team_id])
  end

  def team_module
    return @team_module if defined?(@team_module)

    @team_module = TeamModule.find_by(id: slots_params[:team_module_id])
  end

  def t_round
    @t_round ||= tour&.tournament_round
  end

  def tour
    return @tour if defined?(@tour)

    @tour = Tour.find_by(id: slots_params[:tour_id])
  end
end
