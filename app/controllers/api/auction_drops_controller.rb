module Api
  class AuctionDropsController < Api::ApplicationController
    include Api::AuctionDocument
    include PlayerFormHelper

    def show
      return not_found unless droppable?

      render json: { data: drops_document }
    end

    def update
      return not_found unless droppable?
      return limit_exceeded unless within_limit?

      apply_selection!
      render json: { data: drops_document }
    end

    private

    # Reachable only for the signed-in user's own team while the league auction is
    # in its sales phase (Team#available_transfers relies on the sales auction).
    def droppable?
      auction && team&.sales_period?
    end

    def team
      return @team if defined?(@team)

      @team = current_user&.team_by_league(auction&.league)
    end

    # squad players (droppable) + players who already left their club this auction (locked)
    def player_entries
      entries = player_teams.map do |pt|
        { player: pt.player, status: pt.transfer_status, price: pt.player.transfer_by(team)&.price, player_team_id: pt.id }
      end
      entries += left_transfers.map do |transfer|
        { player: transfer.player, status: 'left', price: transfer.price, player_team_id: nil }
      end
      # same order as the Team page: by position, then by player_team id
      entries.sort_by { |entry| [entry[:player].position_sequence_number, entry[:player_team_id] || 0] }
    end

    def form_map
      return @form_map if defined?(@form_map)

      round = team.next_round&.tournament_round
      @form_map = round ? players_last_rounds_form(player_entries.pluck(:player), round) : {}
    end

    def player_teams
      @player_teams ||= team.player_teams.includes(player: [:positions, :transfers, { club: :tournament }])
    end

    def left_transfers
      @left_transfers ||= team.transfers.left.by_auction(auction.id).includes(player: [:positions, { club: :tournament }]).to_a
    end

    def selected_player_ids
      @selected_player_ids ||= params.permit(player_ids: []).fetch(:player_ids, []).to_set(&:to_i)
    end

    def within_limit?
      selected_player_ids.size <= team.available_transfers
    end

    def apply_selection!
      player_teams.each do |player_team|
        status = selected_player_ids.include?(player_team.player_id) ? :transferable : :untouchable
        player_team.update(transfer_status: status) unless player_team.transfer_status.to_sym == status
      end
      @player_teams = nil # reload so the response reflects the new selection
    end

    def drops_document
      {
        auction: auction_meta,
        team: team_stats,
        players: player_entries.map { |entry| drop_player(entry) }
      }
    end

    def team_stats
      team_hash(team).merge(
        budget: team.budget,
        income: transferable_income,
        possible_budget: team.budget + transferable_income,
        players_dropped: team.prepared_sales_count,
        players_left: left_transfers.size,
        available_transfers: team.available_transfers
      )
    end

    def transferable_income
      player_teams.select(&:transferable?).sum { |pt| pt.player.transfer_by(team)&.price.to_i }
    end

    def drop_player(entry)
      player = entry[:player]

      {
        id: player.id,
        name: player.name,
        first_name: player.first_name,
        avatar_path: player.avatar_path,
        kit_path: player.kit_path,
        positions: player.positions.map { |position| Slot::POS_MAPPING[position.name] },
        club_logo_path: player.club&.logo_path,
        appearances: player.season_scores_count,
        rating: player.season_average_result_score,
        price: entry[:price],
        status: entry[:status],
        player_team_id: entry[:player_team_id],
        form: form_map[player.id] || []
      }
    end

    def limit_exceeded
      render json: { errors: [{ key: 'transfers_limit', message: 'Too many players selected' }] },
             status: :unprocessable_entity
    end
  end
end
