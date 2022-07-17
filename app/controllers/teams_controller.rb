class TeamsController < ApplicationController
  skip_before_action :authenticate_user!, only: %i[show]

  respond_to :html, :json

  helper_method :team

  def show
    respond_to do |format|
      format.html
      format.json { render json: team.players.to_json }
    end
  end

  def create
    redirect_to root_path if current_user.teams.any?

    team = Team.new(create_params)

    if team.save
      team.user.with_team!
      redirect_to new_join_request_path
    else
      render :new
    end
  end

  def edit
    redirect_to user_path(current_user) unless team_of_user?
  end

  def update
    if !team_of_user? || team.update(input_params)
      redirect_to user_path(current_user)
    else
      render :new
    end
  end

  private

  def team
    @team ||= Team.find(params[:id])
  end

  def team_of_user?
    return false unless team.user

    team.user == current_user
  end

  def create_params
    input_params.merge(code: input_params[:human_name].delete(" \t\r\n")[0..3].upcase, name: generate_name, user_id: current_user.id)
  end

  def generate_name
    "#{input_params[:human_name].delete(" \t\r\n")[0..9]}_#{current_user.id}_#{Team.last&.id.to_i + 1}".downcase
  end

  def input_params
    params.require(:team).permit(:human_name, :logo_url)
  end
end
