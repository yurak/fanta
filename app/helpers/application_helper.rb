module ApplicationHelper
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

  def hide_navbar?
    params[:controller] == 'welcome' && params[:action] == 'index'
  end

  def tour_status_class(status)
    case status
    when 'closed' then 'alert-danger'
    when 'inactive' then 'alert-dark'
    when 'set_lineup' then 'alert-success'
    end
  end

  def result_status_class(status)
    case status
    when 'W' then 'badge-success'
    when 'D' then 'badge-secondary'
    when 'L' then 'badge-danger'
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

  def can_moderate?(user)
    user.admin? || user.moderator?
  end
end
