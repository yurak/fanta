module Signups
  # Decides whether a sign-up request came from the bot that has been registering
  # other people's email addresses with us.
  #
  # Two independent signals, because either one alone is escapable:
  #
  # * the honeypot — a field hidden from people, which the bot fills in. It survives a change of
  #   address and of user agent, and costs a real visitor nothing.
  # * the user agent — the bot draws one at random from a list of long-dead browsers, a different
  #   one almost every request. Measured over two days of nginx logs: 133 of 137 sign-up POSTs
  #   carried such an agent, and 420 of the 424 requests carrying one came from the single /16 the
  #   bot works out of. Modern browsers do not look like this.
  #
  # The agent test is the weaker of the two — a list is trivial to update — so it is here to cut
  # today's traffic, not to be the lasting defence.
  class BotDetector
    HONEYPOT_FIELD = :nickname

    # Internet Explorer 9 and older, all long out of support.
    DEAD_IE = /MSIE [1-9]\./i
    # PowerPC Macs, discontinued in 2006.
    DEAD_MAC = /PPC Mac OS X/i
    # Gecko 1.x, meaning Firefox 3.6 and older. Today's `rv:133.0` does not match: the dot is required.
    DEAD_GECKO = /rv:1\.\d/i
    # WebKit before 537. Current Chrome reports 537 and Safari 605, so both stay clear.
    DEAD_WEBKIT = %r{AppleWebKit/(?:[1-4]\d\d|5(?:[0-2]\d|3[0-6]))}i

    DEAD_BROWSERS = Regexp.union(DEAD_IE, DEAD_MAC, DEAD_GECKO, DEAD_WEBKIT).freeze

    # No browser puts a quote in its own user agent. The requests that do arrive almost entirely
    # through Tor exit nodes — a different hand from the one above, equally not a visitor.
    MALFORMED = /["\\]/

    attr_reader :user_agent, :honeypot

    def initialize(user_agent:, honeypot:)
      @user_agent = user_agent.to_s
      @honeypot = honeypot
    end

    def bot?
      reason.present?
    end

    # nil when the request looks human — otherwise why it was refused, for the log
    def reason
      return 'honeypot' if honeypot.present?
      return "malformed user agent: #{user_agent.truncate(120)}" if MALFORMED.match?(user_agent)
      return "dead browser: #{user_agent.truncate(120)}" if DEAD_BROWSERS.match?(user_agent)

      nil
    end
  end
end
