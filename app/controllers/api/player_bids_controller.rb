module Api
  class PlayerBidsController < Api::ApplicationController
    skip_before_action :authenticate_user!, only: %i[show]

    respond_to :json

    helper_method :player_bid

    def show
      if player_bid && auction.closed?
        render json: { data: PlayerBidSerializer.new(player_bid) }
      else
        not_found
      end
    end

    private

    def player_bid
      return @player_bid if defined?(@player_bid)

      @player_bid = PlayerBid.includes(player: [{ player_positions: :position }, :club, :player_season_stats])
                             .find_by(id: params[:id])
      preload_season_round_players if @player_bid
      @player_bid
    end

    def preload_season_round_players
      player = @player_bid.player
      season_rounds = TournamentRound.where(season_id: Season.last&.id).select(:id)

      ActiveRecord::Associations::Preloader.new(
        records: [player], associations: :round_players,
        scope: RoundPlayer.where(tournament_round_id: season_rounds)
      ).call

      ActiveRecord::Associations::Preloader.new(
        records: player.round_players, associations: :tournament_round
      ).call
    end

    def auction
      @auction ||= player_bid.auction_bid.auction
    end
  end
end
