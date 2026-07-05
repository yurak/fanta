class ClubTransfer < ApplicationRecord
  belongs_to :player
  belongs_to :old_club, class_name: 'Club', optional: true
  belongs_to :new_club, class_name: 'Club', optional: true

  validates :start_date, presence: true
  validates :new_club_name, presence: true
  validate :new_club_differs_from_old_club

  private

  def new_club_differs_from_old_club
    return unless old_club_id.present? && new_club_id.present? && old_club_id == new_club_id

    errors.add(:new_club, :same_as_old)
  end

  scope :recent, -> { order(start_date: :desc) }
  scope :tm_sourced, -> { where.not(tm_transfer_id: nil) }
end
