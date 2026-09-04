module Manage
  class RoundPlayersController < BaseController
    def edit
      @round_player = RoundPlayer.includes(:player, tournament_round: :tournament).find(params.expect(:id))
      @clubs = Club.active.order(:name)
    end

    def create
      player = Player.find(params.expect(:player_id))
      result = create_round_player(player)

      redirect_to manage_player_path(player), result
    end

    def update
      @round_player = RoundPlayer.find(params.expect(:id))

      if @round_player.update(round_player_params)
        redirect_to manage_player_path(@round_player.player_id), notice: t('manage.round_players.updated')
      else
        @clubs = Club.active.order(:name)
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def round_player_params
      params.expect(round_player: %i[tournament_round_id club_id])
    end

    def create_round_player(player)
      club = player.club
      tournament_id = club.tournament_id || club.ec_tournament_id
      round = tournament_round_for(tournament_id)
      return { alert: t('manage.round_players.round_not_found', number: params[:number]) } unless round
      return { alert: t('manage.round_players.already_exists', id: round.id) } if exists_for?(player, round)

      RoundPlayer.create!(player: player, tournament_round: round, club: club)
      { notice: t('manage.round_players.created', number: round.number, tournament: round.tournament.name) }
    end

    def tournament_round_for(tournament_id)
      return nil if tournament_id.blank? || params[:number].blank?

      TournamentRound.find_by(tournament_id: tournament_id, season_id: Season.last&.id, number: params[:number])
    end

    def exists_for?(player, round)
      RoundPlayer.exists?(player_id: player.id, tournament_round_id: round.id)
    end
  end
end
