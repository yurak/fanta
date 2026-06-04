class FantaJoinsController < ApplicationController
  def create
    league = find_league

    return redirect_to joins_path unless league
    return redirect_to joins_path if already_joined?(league)

    team = build_team(league)
    return redirect_to joins_path unless team.save

    Result.find_or_create_by(team: team, league: league)

    first_tour = league.tours.order(:number).first
    redirect_to first_tour ? tour_path(first_tour) : league_path(league)
  end

  private

  def find_league
    if join_code_param.present?
      League.active.open_for_join.find_by(join_code: join_code_param) || default_league
    else
      default_league
    end
  end

  def default_league
    League.active.open_for_join.find_by(tournament_id: params.dig(:team, :tournament_id), default_for_join: true)
  end

  def build_team(league)
    Team.new(
      user: current_user,
      tournament: league.tournament,
      league: league,
      name: generate_name,
      human_name: params.dig(:team, :human_name),
      code: params.dig(:team, :code),
      logo_url: params.dig(:team, :logo_url),
      budget: Team::DEFAULT_BUDGET
    )
  end

  def generate_name
    human_name = params.dig(:team, :human_name).to_s
    "#{human_name.delete(" \t\r\n")[0..6]}_#{current_user.id}_#{Team.last&.id.to_i + 1}".downcase
  end

  def join_code_param
    params[:join_code]&.strip&.upcase
  end

  def already_joined?(league)
    current_user.teams
                .joins(:league)
                .where(tournament: league.tournament)
                .exists?(leagues: { open_for_join: true })
  end
end
