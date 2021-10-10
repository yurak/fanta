FactoryBot.define do
  factory :substitute do
    main_mp { association :match_player }
    reserve_mp { association :match_player }
    in_rp { association :round_player }
    out_rp { association :round_player }
  end
end
