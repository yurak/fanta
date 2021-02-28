FactoryBot.define do
  factory :round_player do
    tournament_round { TournamentRound.first || association(:tournament_round) }
    association :player

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

    trait :with_pos_c do
      association :player, :with_pos_c
    end

    trait :with_pos_a do
      association :player, :with_pos_a
    end
  end
end
