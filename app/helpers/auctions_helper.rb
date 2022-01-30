module AuctionsHelper
  def auction_link(auction)
    case auction.status
    when 'initial'
      '#'
    when 'sales'
      team = current_user&.team_by_league(auction.league)
      team ? edit_team_path(team) : '#'
    else
      league_auction_transfers_path(auction.league, auction)
    end
  end
end
