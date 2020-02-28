require 'telegram/bot'

class Tour < ApplicationRecord
  enum status: %i[inactive set_lineup locked closed postponed]

  belongs_to :league
  has_many :matches, dependent: :destroy
  has_many :lineups, dependent: :destroy

  after_update :send_notifications

  scope :closed_postponed, -> { closed.or(postponed) }

  def locked_or_postponed?
    locked? || postponed?
  end

  def deadlined?
    locked? || postponed? || closed?
  end

  def next_number
    number + 1
  end

  def self.active
    # TODO: add League association
    Tour.set_lineup.first || Tour.locked.first
  end

  def match_players
    MatchPlayer.by_tour(id)
  end

  private

  def send_notifications
    Telegram::Sender.call(text: "Deadline for <i>Tour ##{number}</i> changed to <b>#{deadline_str}</b>") if deadline_previously_changed?
    Telegram::Sender.call(text: status_text) if status_previously_changed?
  end

  def status_text
    status_str = set_lineup? ? 'STARTED' : status.upcase
    "<a href='#{ENV['ROOT_URL']}/tours/#{number}'>Tour ##{number}</a> - <b>#{status_str}</b>"
  end

  def deadline_str
    deadline.to_datetime&.strftime('%H:%M, %d %B')
  end
end
