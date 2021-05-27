class LineupsController < ApplicationController
  respond_to :html

  helper_method :lineup, :match_player, :modules, :team, :tour

  def new
    redirect_to team_path(team) unless team_of_user?

    modules
    @lineup = Lineup.new(team_module: team_module, tour: tour, team: team)
    build_match_players
  end

  def create
    if team_of_user?
      @lineup = Lineup.new(lineup_params.merge(team: team))

      # TODO: update create action and specs
      #
      # if @lineup.save
      #   binding.pry
      # end
      # team_lineups_creator.call
      #
      # if team_lineups_creator.lineup.errors.present?
      #   flash[:error] = "Lineup was not created: #{team_lineups_creator.lineup.errors.full_messages.to_sentence}"
      #   redirect_to new_team_lineup_path(team)
      # else
      #   redirect_to edit_team_lineup_path(team, team_lineups_creator.lineup)
      # end
    else
      redirect_to team_path(team)
    end
  end

  def clone
    team_lineups_cloner.call if team_of_user?

    redirect_to tour_path(tour)
  end

  def edit
    redirect_to match_path(lineup.match) unless editable?
  end

  def edit_module
    if editable?
      modules
    else
      redirect_to match_path(lineup.match)
    end
  end

  def update
    if duplicate_players&.any?
      flash[:error] = "ERROR! Same player on multiple positions: #{duplicate_names}"
      redirect_to edit_team_lineup_path(team, lineup)
    else
      if editable?
        recount_round_players_params
        lineup.update(update_lineup_params)
      end

      redirect_to match_path(lineup.match)
    end
  end

  def substitutions
    redirect_to match_path(lineup.match) unless sub_available?
  end

  def subs_update
    if (can? :subs_update, Lineup) && call_substituter
      redirect_to match_path(lineup.match)
    else
      redirect_to substitutions_team_lineup_path(team, lineup)
    end
  end

  private

  # def team_lineups_creator
  #   @team_lineups_creator ||= TeamLineups::Creator.new(params: lineup_params, team: team)
  # end

  def team_lineups_cloner
    @team_lineups_cloner ||= TeamLineups::Cloner.new(team: team, tour: tour)
  end

  def lineup_params
    params.fetch(:lineup, {}).permit(:team_module_id, :tour_id, match_players_attributes: {})
  end

  def build_match_players
    @lineup.players_count.times { @lineup.match_players.build }
  end

  def update_lineup_params
    params.fetch(:lineup, {}).permit(:team_module_id, match_players_attributes: {})
  end

  def recount_round_players_params
    return if params[:lineup][:match_players_attributes].blank?

    params[:lineup][:match_players_attributes].each do |k, _|
      next unless params[:lineup][:match_players_attributes][k][:round_player_id]

      player = Player.find(params[:lineup][:match_players_attributes][k][:round_player_id])
      round_player = RoundPlayer.find_or_create_by(tournament_round: tournament_round, player: player)
      params[:lineup][:match_players_attributes][k][:round_player_id] = round_player.id
    end
  end

  def duplicate_players
    return if params[:lineup][:match_players_attributes].blank?

    player_ids = params[:lineup][:match_players_attributes].values.each_with_object([]) { |el, p_ids| p_ids << el[:round_player_id] }
    player_ids.find_all { |id| player_ids.rindex(id) != player_ids.index(id) }
  end

  def duplicate_names
    Player.find(duplicate_players.uniq).map(&:name).join(', ')
  end

  def lineup
    @lineup ||= Lineup.find(params[:id])
  end

  def team
    @team ||= Team.find(params[:team_id])
  end

  def team_module
    @team_module ||= TeamModule.find(params[:team_module_id] || TeamModule.first.id)
  end

  def tour
    @tour ||= Tour.find(params[:tour_id])
  end

  def tournament_round
    lineup.tour.tournament_round
  end

  def modules
    @modules ||= TeamModule.all
  end

  def match_player
    MatchPlayer.find(params[:mp])
  end

  def team_of_user?
    team.user == current_user
  end

  def editable?
    lineup.tour.set_lineup? && team_of_user?
  end

  def sub_available?
    lineup.tour.locked_or_postponed? && match_player.not_played? && (can? :substitutions, Lineup)
  end

  def call_substituter
    MatchPlayers::Substituter.call(out_mp_id: params[:out_mp_id], in_mp_id: params[:in_mp_id])
  end
end
