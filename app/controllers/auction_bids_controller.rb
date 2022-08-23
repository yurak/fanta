class AuctionBidsController < ApplicationController
  respond_to :html

  helper_method :auction_bid, :auction_round, :dumped_player_ids, :league, :team

  def new
    if team && auction_round.active?
      redirect_to auction_round_path(auction_round) if auction_round.bid_exist?(team) || team.full_squad?

      @auction_bid = AuctionBid.new(auction_round: auction_round, team: team)
      team.vacancies.times { @auction_bid.player_bids.build }
    else
      redirect_to auction_round_path(auction_round)
    end
  end

  def create
    @auction_bid = AuctionBid.new(auction_bid_params.merge(team: team, auction_round: auction_round))

    if !auction_round.bid_exist?(team) && valid_bid? && @auction_bid.save
      redirect_to auction_round_path(auction_round)
    else
      redirect_to new_auction_round_auction_bid_path(auction_round)
    end
  end

  def edit
    redirect_to auction_round_path(auction_round) unless editable?
  end

  def update
    if valid_bid?
      auction_bid.update(auction_bid_params)

      redirect_to auction_round_path(auction_round)
    else
      redirect_to edit_auction_round_auction_bid_path(auction_round, auction_bid)
    end
  end

  private

  def auction_bid_params
    params.fetch(:auction_bid, {}).permit(player_bids_attributes: {})
  end

  def valid_bid?
    return false unless editable?
    return false if duplicate_players&.any?
    return false if players_ids.count < team.vacancies
    return false if total_price > team.budget
    return false if gk_count < Team::MIN_GK
    return false if contains_dumped?

    true
  end

  def total_price
    auction_bid_params[:player_bids_attributes].values.each_with_object([]) { |el, prices| prices << el[:price] }.sum(&:to_i)
  end

  def players_ids
    auction_bid_params[:player_bids_attributes].values.each_with_object([]) { |el, p_ids| p_ids << el[:player_id].to_i }.compact_blank
  end

  def duplicate_players
    players_ids&.find_all { |id| players_ids.rindex(id) != players_ids.index(id) }
  end

  def gk_count
    @gk_count ||= Player.by_position('Por').where(id: players_ids + team.players.map(&:id)).count
  end

  def dumped_player_ids
    team.transfers.outgoing.by_auction(auction_round.auction).pluck(:player_id)
  end

  def contains_dumped?
    players_ids.intersection(dumped_player_ids).any?
  end

  def editable?
    return false unless team&.user

    team.user == current_user && team == auction_bid.team && auction_round.active?
  end

  def auction_bid
    @auction_bid ||= AuctionBid.find_by(id: params[:id])
  end

  def auction_round
    @auction_round ||= AuctionRound.find(params[:auction_round_id])
  end

  def league
    @league ||= auction_round.league
  end

  def team
    @team ||= current_user&.team_by_league(league)
  end
end
