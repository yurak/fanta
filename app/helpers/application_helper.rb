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

  def flash_class(level)
    case level
    when 'notice' then 'alert alert-info'
    when 'success' then 'alert alert-success'
    when 'error' then 'alert alert-danger'
    when 'alert' then 'alert alert-danger'
    end
  end

  def status_class(element, status)
    case status
    when 'ready' then "#{element}-success"
    when 'injured' then "#{element}-danger"
    when 'disqualified' then "#{element}-secondary"
    when 'problematic' then "#{element}-warning"
    end
  end

  def tour_status_class(status)
    case status
    when 'closed' then 'alert-danger'
    when 'postponed' then 'alert-warning'
    when 'inactive' then 'alert-dark'
    when 'set_lineup' then 'alert-success'
    end
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
    if match_player.player_score.positive?
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
