module ApplicationHelper
  def external_actions?
    %w[welcome devise/sessions join_requests].include?(params[:controller])
  end

  def active_tournaments
    Tournament.with_clubs
  end

  def random_player_img_path
    player = %w[donnarumma duvan dybala ibra maguire malina virgil yarmola].sample
    "welcome_persons/#{player}.png"
  end
end
