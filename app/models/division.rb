class Division < ApplicationRecord
  has_many :leagues, dependent: :destroy

  def name
    return '' unless level

    level + number.to_s
  end
end
