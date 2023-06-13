module AuctionsHelper
  def auction_link(auction)
    case auction.status
    when 'initial'
      '#'
    when 'sales'
      team = current_user&.team_by_league(auction.league)
      team ? edit_team_player_team_path(team, team.player_teams.first) : '#'
    when 'blind_bids'
      auction.auction_rounds.active.any? ? auction_round_path(auction.auction_rounds.active.first) : '#'
    else
      league_auction_transfers_path(auction.league, auction)
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
end
