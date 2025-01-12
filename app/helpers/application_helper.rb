module ApplicationHelper
  def active_tournaments
    Tournament.with_clubs.order(:id) + Tournament.with_ec_clubs
  end

  def open_tournaments
    Tournament.open_join
  end

  def position_number(index)
    return '🥇' if index == 1
    return '🥈' if index == 2
    return '🥉' if index == 3

    index
  end

  def position_manager_number(index)
    return '🥇 #1' if index == 1
    return '🥈 #2' if index == 2
    return '🥉 #3' if index == 3

    "##{index}"
  end

  def ordinalize_number(number)
    return '-' unless number

    case I18n.locale
    when :en
      number.ordinalize
    else
      number
    end
  end
end
