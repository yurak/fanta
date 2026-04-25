FactoryBot.define do
  factory :weekly_team do
    team_module { TeamModule.first || association(:team_module) }
    season { Season.last || association(:season) }
    number { 1 }
    mode { :top }
    round_ids { [] }

    trait :with_player do
      after(:create) do |weekly_team|
        round_player = create(:round_player, :with_pos_por, score: 7)
        slot = weekly_team.team_module.slots.first
        create(:weekly_team_player, weekly_team: weekly_team, slot: slot, round_player: round_player, total: 7.0)
      end
    end
  end
end
