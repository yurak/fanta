FactoryBot.define do
  factory :club do
    sequence(:name) { |i| "#{FFaker::Company.name}#{i}" }
    sequence(:code) { |i| i < 99 ? "c#{i}" : i.to_s }

    tournament { Tournament.first || association(:tournament) }

    trait :with_players_by_pos do
      after(:create) do |club|
        create_list(:player, 3, :with_pos_por, club: club)
        create_list(:player, 3, :with_pos_dc, club: club)
        create_list(:player, 4, :with_pos_dd_ds_e, club: club)
        create_list(:player, 2, :with_pos_m, club: club)
        create_list(:player, 3, :with_pos_c, club: club)
        create_list(:player, 3, :with_pos_w_a, club: club)
        create_list(:player, 3, :with_pos_pc, club: club)
      end
    end
  end
end
