require 'telegram/bot'

class Tour < ApplicationRecord
  belongs_to :league
  belongs_to :tournament_round

  has_many :matches, dependent: :destroy
  has_many :lineups, dependent: :destroy

  enum status: { inactive: 0, set_lineup: 1, locked: 2, closed: 3, postponed: 4 }

  after_update :send_notifications

  scope :closed_postponed, -> { closed.or(postponed) }

  scope :active, -> { set_lineup.or(locked) }

  def locked_or_postponed?
    locked? || postponed?
  end

  def deadlined?
    locked? || postponed? || closed?
  end

  def unlocked?
    inactive? || set_lineup?
  end

  def next_number
    number + 1
  end

  def real_number
    number + league.tour_difference
  end

  def match_players
    MatchPlayer.by_tour(id)
  end

  def round_players
    RoundPlayer.by_tour(id)
  end

  private

  def send_notifications
    # TODO: need TG implementation
    # Telegram::Sender.call(text: "Deadline for <i>Tour ##{number}</i> changed to <b>#{deadline_str}</b>") if deadline_previously_changed?
    # Telegram::Sender.call(text: status_text) if status_previously_changed?
  end

  def status_text
    status_str = set_lineup? ? 'STARTED' : status.upcase
    "<a href='#{ENV['ROOT_URL']}/tours/#{number}'>Tour ##{number}</a> - <b>#{status_str}</b>"
  end

  def deadline_str
    deadline.to_datetime&.strftime('%H:%M, %d %B')
  end
end
