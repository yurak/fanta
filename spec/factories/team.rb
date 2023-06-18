FactoryBot.define do
  factory :team do
    sequence(:name) { FFaker::Internet.slug[0...14] }
    human_name { name }
    sequence(:code) { FFaker::Internet.slug[0..2] }

    association :league

    trait :with_user do
      association :user
    end

    trait :with_players do
      after(:create) do |team|
        create_list(:player_team, 25, team: team)
      end
    end

    trait :with_players_by_pos do
      after(:create) do |team|
        create_list(:player_team, 3, team: team, player: create(:player, :with_pos_por))
        create_list(:player_team, 6, team: team, player: create(:player, :with_pos_dc))
        create_list(:player_team, 4, team: team, player: create(:player, :with_pos_dd_ds_e))
        create_list(:player_team, 2, team: team, player: create(:player, :with_pos_m))
        create_list(:player_team, 3, team: team, player: create(:player, :with_pos_c))
        create_list(:player_team, 3, team: team, player: create(:player, :with_pos_w_a))
        create_list(:player_team, 4, team: team, player: create(:player, :with_pos_pc))
      end
    end

    trait :with_15_players do
      after(:create) do |team|
        create_list(:player_team, 15, team: team)
      end
    end

    trait :with_20_players do
      after(:create) do |team|
        create_list(:player_team, 20, team: team)
      end
    end

    trait :with_25_players do
      after(:create) do |team|
        create_list(:player_team, 25, team: team)
      end
    end

    trait :with_full_squad do
      after(:create) do |team|
        create_list(:player_team, Team::MAX_PLAYERS, team: team)
      end
    end

    trait :with_lineup do
      after(:create) do |team|
        create_list(:player_team, 25, team: team)
        lineup = create(:lineup, team: team)
        mp_count = 0
        team.players.each do |player|
          rp = create(:round_player, player: player)
          next if mp_count >= 18

          create(:match_player, round_player: rp, lineup: lineup)
          mp_count += 1
        end
      end
    end

    trait :with_result do
      after(:create) do |team|
        create(:result, team: team, league: team.league)
      end
    end

    trait :with_matches do
      host_matches { build_list(:match, 2) }
      guest_matches { build_list(:match, 3) }
    end

    trait :with_league_matches do
      host_matches { build_list(:match, 3, tour: create(:tour, league: league)) }
      guest_matches { build_list(:match, 2, tour: create(:tour, league: league)) }
    end
  end
end
