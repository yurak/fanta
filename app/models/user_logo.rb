class UserLogo < ApplicationRecord
  belongs_to :user

  enum :status, { pending: 0, approved: 1, rejected: 2 }

  validates :url, presence: true

  scope :kept, -> { where(deleted_at: nil) }
  scope :discarded, -> { where.not(deleted_at: nil) }
  scope :recent, -> { order(created_at: :desc) }

  def in_use?
    user.teams.exists?(logo_url: url)
  end

  def discard
    return false if in_use?

    update(deleted_at: Time.current)
  end

  def discarded?
    deleted_at.present?
  end
end
