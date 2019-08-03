module ApplicationHelper

  def flash_class(level)
    case level
    when 'notice' then 'alert alert-info'
    when 'success' then 'alert alert-success'
    when 'error' then 'alert alert-danger'
    when 'alert' then 'alert alert-danger'
    end
  end

  def status_class(status)
    case status
    when 'ready' then 'badge-primary'
    when 'injured' then 'badge-danger'
    when 'disqualified' then 'badge-secondary'
    end
  end


  def tour_status_class(status)
    case status
    when 'closed' then 'alert-danger'
    when 'inactive' then 'alert-dark'
    when 'set_lineup' then 'alert-success'
    end
  end
end
