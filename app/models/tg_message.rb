class TgMessage < ApplicationRecord
  validates :update_id, presence: true
end
