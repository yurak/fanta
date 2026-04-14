class TeamsController < ApplicationController
  respond_to :html, :json

  helper_method :team

  def show
    respond_to do |format|
      format.html
      format.json { render json: team.players.to_json }
    end
  end

  def edit
    redirect_to user_path(current_user) unless team_of_user?
  end

  def create
    if existing_team_id.present?
      join_with_existing_team
    else
      join_with_new_team
    end
  end

  def update
    if !team_of_user? || team.update(update_params)
      redirect_to user_path(current_user)
    else
      render :edit
    end
  end

  private

  def team
    @team ||= Team.includes(
      players: %i[positions club],
      transfers: { player: %i[positions club] },
      league: %i[teams tours]
    ).find(params[:id])
  end

  def team_of_user?
    return false unless team.user

    team.user == current_user
  end

  def join_with_new_team
    team = Team.new(create_params)
    if team.save
      bid = create_join_records(team)
      if bid.nil?
        team.destroy
        return redirect_to joins_path, alert: flash[:alert]
      end
      redirect_to auction_bid_path(bid)
    else
      redirect_to joins_path, alert: team.errors.full_messages.join(', ')
    end
  end

  def join_with_existing_team
    team = current_user.teams.find_by(id: existing_team_id)
    return redirect_to joins_path, alert: t('join.team_not_found') unless team

    bid = create_join_records(team)
    return redirect_to joins_path, alert: flash[:alert] if bid.nil?

    redirect_to auction_bid_path(bid)
  end

  def create_join_records(team)
    tournament = Tournament.find(join_tournament_id)
    bid = AuctionBid.create!(team: team, status: :initial)
    Team::JOIN_SLOTS.times { bid.player_bids.create! }
    Join.create!(user: current_user, tournament: tournament, team: team, auction_bid: bid, status: :initial)
    bid
  rescue ActiveRecord::RecordInvalid => e
    flash[:alert] = e.message
    nil
  end

  def create_params
    input_params.merge(
      code: input_params[:code]&.upcase,
      name: generate_name,
      user_id: current_user.id
    )
  end

  def generate_name
    "#{input_params[:human_name].delete(" \t\r\n")[0..6]}_#{current_user.id}_#{Team.last&.id.to_i + 1}".downcase
  end

  def update_params
    input_params.merge(code: input_params[:code]&.upcase)
  end

  def join_tournament_id
    input_params[:tournament_id]
  end

  def existing_team_id
    input_params[:team_id]
  end

  def input_params
    params.require(:team).permit(:code, :human_name, :logo_url, :tournament_id, :team_id)
  end
end
