class ClubTransfer < ApplicationRecord
  belongs_to :player
  belongs_to :old_club, class_name: 'Club', optional: true
  belongs_to :new_club, class_name: 'Club', optional: true

  validates :start_date, presence: true
  validates :new_club_name, presence: true
  validate :new_club_differs_from_old_club
  validate :contract_expires_after_start, if: -> { start_date.present? && contract_expires_on.present? }

  private

  def new_club_differs_from_old_club
    return unless old_club_id.present? && new_club_id.present? && old_club_id == new_club_id

    errors.add(:new_club, :same_as_old)
  end

  def contract_expires_after_start
    errors.add(:contract_expires_on, :before_start_date) if contract_expires_on < start_date
  end

  scope :recent, -> { order(start_date: :desc) }
end
