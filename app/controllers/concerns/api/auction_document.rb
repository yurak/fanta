module Api
  module AuctionDocument
    extend ActiveSupport::Concern

    private

    def auction
      return @auction if defined?(@auction)

      @auction = Auction.find_by(id: params[:auction_id], league_id: params[:league_id])
    end

    def auction_meta
      { number: auction.number, status: auction.status, deadline: auction.deadline }
    end

    def current_team_id
      return @current_team_id if defined?(@current_team_id)

      @current_team_id = current_user&.team_by_league(auction.league)&.id
    end

    # keep the signed-in user's team on top, the rest in the service's value order
    def teams_current_first(groups)
      return groups unless current_team_id

      mine, others = groups.partition { |group| group.team.id == current_team_id }
      mine + others
    end

    def ranking(entry)
      { team: team_hash(entry.team), value: entry.value }
    end

    def transfer_row(transfer)
      {
        id: transfer.id,
        price: transfer.price,
        status: transfer.status,
        player: player_hash(transfer.player),
        team: team_hash(transfer.team)
      }
    end

    def team_hash(team)
      { id: team.id, human_name: team.human_name, logo_path: team.logo_path }
    end

    def player_hash(player)
      {
        id: player.id,
        name: player.name,
        first_name: player.first_name,
        avatar_path: player.avatar_path,
        kit_path: player.kit_path,
        positions: player.positions.map(&:name)
      }
    end
  end
end
