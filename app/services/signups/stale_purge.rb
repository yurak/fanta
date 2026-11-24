module Signups
  # Finds — and on request removes — the sign-ups the bot leaves behind: an account is created, the
  # confirmation mail goes to a stranger who never asked for it, and nobody ever follows the link.
  #
  # Deliberately cautious. `config.confirm_within` is not set in this application, so a confirmation
  # link never expires and somebody could in principle still use a months-old one. A row therefore
  # has to be both old enough AND carry nothing at all before it is touched. Emptiness is checked
  # per user rather than assumed: it holds for today's leftovers, but this will be run again.
  class StalePurge
    DEFAULT_DAYS = 30
    OWNED = %i[teams joins player_requests user_titles user_logos wishlists].freeze

    attr_reader :days

    def initialize(days: DEFAULT_DAYS)
      @days = days.to_i
    end

    def removable
      @removable ||= candidates.select { |user| empty?(user) }
    end

    def kept
      @kept ||= candidates.reject { |user| empty?(user) }
    end

    def newer_count
      User.where(confirmed_at: nil).where(created_at: days.days.ago..).count
    end

    def purge!
      removable.count(&:destroy)
    end

    private

    def candidates
      @candidates ||= User.where(confirmed_at: nil).where(created_at: ..days.days.ago).to_a
    end

    def empty?(user)
      OWNED.none? { |name| user.public_send(name).exists? } && user.user_profile.nil?
    end
  end
end
