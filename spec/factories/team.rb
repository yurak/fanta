FactoryBot.define do
  factory :team do
    sequence(:name) { |i| "#{FFaker::Internet.slug[0...15]}#{i}" }
    human_name { name }
    sequence(:code) { |i| i < 99 ? "c#{i}" : i.to_s }

    association :league

    trait :with_user do
      association :user
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
