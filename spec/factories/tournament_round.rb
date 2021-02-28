FactoryBot.define do
  factory :tournament_round do
    sequence(:number) { |i| i }

    tournament { Tournament.first || association(:tournament) }
    season { Season.first || association(:season) }
  end
end
