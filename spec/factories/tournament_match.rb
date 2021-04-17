FactoryBot.define do
  factory :tournament_match do
    tournament_round

    host_club { association :club }
    guest_club { association :club }
  end
end
