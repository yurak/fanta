module PositionsHelper
  def position_name(position)
    current_user&.ital_pos_naming ? position.name : position.human_name
  end

  def slot_position_name(position_name)
    current_user&.ital_pos_naming ? position_name : Slot::POS_MAPPING[position_name]
  end

  def modules_path
    current_user&.ital_pos_naming ? 'modules/ital/' : 'modules/classic/'
  end
end
