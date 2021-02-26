module ApplicationHelper
  def external_actions?
    %w[welcome devise/sessions join_requests].include?(params[:controller])
  end

  # TODO: old def, remove after new UI implementation
  def hide_navbar?
    external_actions?
  end

  def all_tournaments
    Tournament.all
  end

  def active_tournaments
    Tournament.with_clubs
  end

  def lineup_class(status)
    status ? 'lineup-completed' : 'lineup-uncompleted'
  end

  def squad_class(match_player)
    if match_player.real_position
      'alert-success'
    elsif match_player.not_in_squad?
      'alert-danger'
    else
      'alert-warning'
    end
  end

  def score_class(match_player)
    if match_player.score.positive?
      'positive-score'
    else
      'absent-score'
    end
  end

  def random_player_img_path
    player = %w[donnarumma duvan dybala ibra maguire malina virgil yarmola].sample
    "welcome_persons/#{player}.png"
  end
end
