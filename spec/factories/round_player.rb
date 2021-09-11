FactoryBot.define do
  factory :round_player do
    tournament_round { TournamentRound.first || association(:tournament_round) }
    association :player

    trait :with_team do
      association :player, :with_team
    end

    trait :with_score_five do
      score { 5 }
    end

    trait :with_score_six do
      score { 6 }
    end

    trait :with_score_seven do
      score { 7 }
    end

    trait :with_pos_por do
      association :player, :with_pos_por
    end

    trait :with_pos_dc do
      association :player, :with_pos_dc
    end

    trait :with_pos_dd do
      association :player, :with_pos_dd
    end

    trait :with_pos_e do
      association :player, :with_pos_e
    end

    trait :with_pos_m do
      association :player, :with_pos_m
    end

    trait :with_pos_c do
      association :player, :with_pos_c
    end

    trait :with_pos_w do
      association :player, :with_pos_w
    end

    trait :with_pos_a do
      association :player, :with_pos_a
    end

    trait :with_pos_pc do
      association :player, :with_pos_pc
    end

    trait :with_tournament_match do
      after(:create) do |rp|
        create(:tournament_match, tournament_round: rp.tournament_round, host_club: rp.club)
      end
    end

    trait :with_finished_t_match do
      after(:create) do |rp|
        create(:tournament_match, tournament_round: rp.tournament_round, host_club: rp.club, host_score: 1)
      end
    end
  end
end
