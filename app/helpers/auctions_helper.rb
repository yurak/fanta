module AuctionsHelper
  def auction_link(auction)
    case auction.status
    when 'blind_bids', 'live'
      if auction.auction_rounds.active.any?
        auction_round_path(auction.auction_rounds.active.first)
      else
        league_auction_transfers_path(auction.league, auction)
      end
    else
      league_auction_path(auction.league, auction)
    end
  end

  def dropping_link(auction)
    case auction.status
    when 'initial', 'live'
      league_auction_path(auction.league, auction)
    when 'sales'
      team = current_user&.team_by_league(auction.league)
      team ? edit_team_player_team_path(team, team.player_teams.first) : league_auction_path(auction.league, auction)
    else
      league_auction_transfers_path(auction.league, auction, type: 'out')
    end
  end

  def auction_status(auction)
    if auction.closed?
      'completed'
    elsif auction.sales? || (auction.initial? && auction.deadline)
      'coming_soon'
    elsif auction.live? || auction.blind_bids?
      'ongoing'
    else
      'to_be_decided'
    end
  end

  def auction_dates(auction, user = nil)
    if auction.initial? || auction.sales?
      auction.deadline ? "Started on #{auction.deadline.strftime('%b %e, %Y')}" : auction.base_date
    elsif auction.blind_bids?
      auction_local_time(auction.deadline, user)
    elsif auction.closed?
      "#{auction.auction_rounds.first&.created_at&.strftime('%b %e')} - #{auction.auction_rounds.last&.updated_at&.strftime('%b %e, %Y')}"
    else
      '--:--'
    end
  end

  def auction_local_time(time, user)
    user&.local_time(time, '%a, %b %e, %H:%M') || time&.strftime('%a, %b %e, %H:%M')&.to_s
  end

  def auction_dropping_status(auction)
    if auction.closed? || auction.live? || auction.blind_bids?
      'completed'
    elsif auction.sales?
      'ongoing'
    elsif auction.initial?
      'coming_soon'
    end
  end

  def user_auction_bid(auction_round, league)
    return unless current_user

    auction_round.auction_bids.find_by(team: current_user&.team_by_league(league))
  end

  def next_bid_status(auction_bid)
    case auction_bid&.status
    when 'initial', 'ongoing'
      'submitted'
    when 'submitted'
      'completed'
    when 'completed'
      'ongoing'
    else
      ''
    end
  end

  def max_bid(league)
    @max_bid ||= current_user&.team_by_league(league)&.max_rate
  end

  def min_bid(auction_round, player)
    return 1 unless player

    if auction_round.nil? || auction_round.min_price_active?
      player.stats_price
    else
      1
    end
  end

  def formations_js_data
    TeamModule.includes(:slots).each_with_object({}) do |tm, hash|
      key = "f#{tm.name.delete('-')}"
      line_up = tm.slots
                  .reject { |s| s.position == Position::GOALKEEPER }
                  .sort_by(&:number)
                  .map(&:position)
      hash[key] = { lineUp: line_up, lineUpWithReserve: line_up * 2 }
    end.to_json
  end
end
