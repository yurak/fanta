FactoryBot.define do
  factory :weekly_team_player do
    weekly_team
    slot { weekly_team.team_module.slots.first }
    round_player factory: %i[round_player with_pos_por], score: 7
    total { 7.0 }
  end
end
