module Scores
  # Caps how long a single scrape run may spend sleeping between retries.
  class ScrapeBudget
    DEFAULT_LIMIT = 60

    attr_reader :spent

    def initialize(limit: DEFAULT_LIMIT)
      @limit = limit
      @spent = 0
    end

    def take(seconds)
      remaining = @limit - @spent
      return 0 unless remaining.positive?

      granted = [seconds, remaining].min
      @spent += granted
      granted
    end

    def exhausted?
      @spent >= @limit
    end
  end
end
