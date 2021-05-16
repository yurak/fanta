FactoryBot.define do
  factory :national_match do
    tournament_round

    host_team { association :national_team }
    guest_team { association :national_team }
  end
end
