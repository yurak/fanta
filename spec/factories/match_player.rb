FactoryBot.define do
  factory :match_player do
    association :round_player, :with_team
    association :lineup

    trait :with_score do
      association :round_player, :with_score_six
    end

    trait :with_score_and_cleansheet do
      association :round_player, :with_score_six, cleansheet: true
    end

    trait :with_real_position do
      association :round_player, :with_pos_a
      real_position { 'W/A' }
    end

    trait :with_position_malus do
      association :round_player, :with_pos_dc
      real_position { 'Dd' }
    end

    factory :por_match_player do
      association :round_player, :with_pos_por, :with_score_six
      real_position { 'Por' }
    end

    factory :dc_match_player do
      association :round_player, :with_pos_dc, :with_score_six
      real_position { 'Dc' }
    end

    factory :e_match_player do
      association :round_player, :with_pos_e, :with_score_six
      real_position { 'E' }
    end

    factory :m_match_player do
      association :round_player, :with_pos_m, :with_score_six
      real_position { 'M' }
    end

    factory :c_match_player do
      association :round_player, :with_pos_c, :with_score_six
      real_position { 'C' }
    end

    factory :w_match_player do
      association :round_player, :with_pos_w, :with_score_six
      real_position { 'W/A' }
    end

    factory :pc_match_player do
      association :round_player, :with_pos_pc, :with_score_six
      real_position { 'A/Pc' }
    end
  end
end
