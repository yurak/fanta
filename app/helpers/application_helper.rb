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
end
