module AuctionsHelper
  def auction_link(auction)
    case auction.status
    when 'initial'
      '#'
    when 'sales'
      current_user ? edit_team_path(current_user&.team_by_league(auction.league)) : '#'
    else
      league_auction_transfers_path(auction.league, auction)
    end
  end
end
