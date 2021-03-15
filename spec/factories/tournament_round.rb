FactoryBot.define do
  factory :tournament_round do
    sequence(:number) { |i| i }

    tournament { Tournament.first || association(:tournament) }
    season { Season.last || association(:season) }
  end
end
