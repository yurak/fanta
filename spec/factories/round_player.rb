FactoryBot.define do
  factory :round_player do
    tournament_round { TournamentRound.first || association(:tournament_round) }
    player

    trait :with_team do
      player factory: %i[player with_team]
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
      player factory: %i[player with_pos_por]
    end

    trait :with_pos_dc do
      player factory: %i[player with_pos_dc]
    end

    trait :with_pos_dd do
      player factory: %i[player with_pos_dd]
    end

    trait :with_pos_dc_ds_e do
      player factory: %i[player with_pos_dc_ds_e]
    end

    trait :with_pos_e do
      player factory: %i[player with_pos_e]
    end

    trait :with_pos_m do
      player factory: %i[player with_pos_m]
    end

    trait :with_pos_c do
      player factory: %i[player with_pos_c]
    end

    trait :with_pos_e_c do
      player factory: %i[player with_pos_c with_pos_e]
    end

    trait :with_pos_w do
      player factory: %i[player with_pos_w]
    end

    trait :with_pos_a do
      player factory: %i[player with_pos_a]
    end

    trait :with_pos_pc do
      player factory: %i[player with_pos_pc]
    end

    trait :with_tournament_match do
      after(:create) do |rp|
        create(:tournament_match, tournament_round: rp.tournament_round, host_club: rp.player.club)
      end
    end

    trait :with_finished_t_match do
      after(:create) do |rp|
        create(:tournament_match, tournament_round: rp.tournament_round, host_club: rp.player.club, host_score: 1)
      end
    end
  end
end
