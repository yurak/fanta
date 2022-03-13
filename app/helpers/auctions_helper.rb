module AuctionsHelper
  def auction_link(auction)
    case auction.status
    when 'initial'
      '#'
    when 'sales'
      team = current_user&.team_by_league(auction.league)
      team ? edit_team_path(team) : '#'
    when 'blind_bids'
      auction.auction_rounds.any? ? auction_round_path(auction.auction_rounds.active.first) : '#'
    else
      league_auction_transfers_path(auction.league, auction)
    end
  end

  def auction_message(auction)
    case auction.status
    when 'sales'
      t('auction.sales_msg', date: auction.deadline&.strftime('%H:%M %e/%m/%y') || '--:--')
    when 'blind_bids'
      t('auction.blind_bids_msg', date: auction.event_time&.strftime('%H:%M %e/%m/%y') || '--:--')
    when 'live'
      t('auction.live_msg', date: auction.event_time&.strftime('%H:%M %e/%m/%y') || '--:--')
    else
      ''
    end
  end

  def user_auction_bid(auction_round, league)
    return unless current_user

    auction_round.auction_bids.find_by(team: current_user&.team_by_league(league))
  end
end
