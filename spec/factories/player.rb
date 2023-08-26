FactoryBot.define do
  factory :player do
    sequence(:name) { |i| "#{FFaker::Name.last_name}#{i}" }
    first_name { FFaker::Name.first_name }
    club { Club.first || association(:club) }

    trait :with_team do
      after(:create) do |player|
        create(:team, players: [player])
        player.reload
      end
    end

    trait :with_national_team do
      after(:create) do |player|
        create(:national_team, players: [player])
        player.reload
      end
    end

    trait :with_scores do
      after(:create) do |player|
        create(:round_player, player: player, tournament_round: create(:tournament_round, tournament: player.club.tournament), score: 6)
        create(:round_player, player: player, tournament_round: create(:tournament_round, tournament: player.club.tournament), score: 6)
        create(:round_player, player: player, tournament_round: create(:tournament_round, tournament: player.club.tournament), score: 8)
      end
    end

    trait :with_eurocup_scores do
      club { association :club, ec_tournament: Tournament.find_by(code: Scores::Injectors::Strategy::EUROPE_CL) }

      after(:create) do |player|
        create(:round_player, player: player, tournament_round: create(:tournament_round, tournament: player.club.ec_tournament), score: 6)
        create(:round_player, player: player, tournament_round: create(:tournament_round, tournament: player.club.ec_tournament), score: 6)
        create(:round_player, player: player, tournament_round: create(:tournament_round, tournament: player.club.ec_tournament), score: 8)
      end
    end

    trait :with_scores_n_bonuses do
      after(:create) do |player|
        create(:round_player, player: player, tournament_round: create(:tournament_round, tournament: player.club.tournament), score: 6,
                              yellow_card: true, played_minutes: 34)
        create(:round_player, player: player, tournament_round: create(:tournament_round, tournament: player.club.tournament), score: 6,
                              played_minutes: 49)
        create(:round_player, player: player, tournament_round: create(:tournament_round, tournament: player.club.tournament), score: 8,
                              goals: 2, played_minutes: 77)
      end
    end

    trait :with_second_season do
      after(:create) do |player|
        create(:season)

        create(:round_player, player: player, tournament_round: create(:tournament_round, tournament: player.club.tournament), score: 5,
                              red_card: true, played_minutes: 77)
        create(:round_player, player: player, tournament_round: create(:tournament_round, tournament: player.club.tournament), score: 8,
                              goals: 2, played_minutes: 90)
        create(:round_player, player: player, tournament_round: create(:tournament_round, tournament: player.club.tournament), score: 6,
                              yellow_card: true, played_minutes: 23)
        create(:round_player, player: player, tournament_round: create(:tournament_round, tournament: player.club.tournament), score: 7,
                              goals: 1, yellow_card: true, played_minutes: 90)
      end
    end

    trait :with_pos_por do
      after(:create) do |player|
        create(:player_position, player: player, position: Position.find_by(name: Position::GOALKEEPER))
      end
    end

    trait :with_pos_dc do
      after(:create) do |player|
        create(:player_position, player: player, position: Position.find_by(name: Position::CENTER_BACK))
      end
    end

    trait :with_pos_dd do
      after(:create) do |player|
        create(:player_position, player: player, position: Position.find_by(name: Position::RIGHT_BACK))
      end
    end

    trait :with_pos_dd_ds_e do
      after(:create) do |player|
        create(:player_position, player: player, position: Position.find_by(name: Position::RIGHT_BACK))
        create(:player_position, player: player, position: Position.find_by(name: Position::LEFT_BACK))
        create(:player_position, player: player, position: Position.find_by(name: Position::WING_BACK))
      end
    end

    trait :with_pos_dc_ds_e do
      after(:create) do |player|
        create(:player_position, player: player, position: Position.find_by(name: Position::CENTER_BACK))
        create(:player_position, player: player, position: Position.find_by(name: Position::LEFT_BACK))
        create(:player_position, player: player, position: Position.find_by(name: Position::WING_BACK))
      end
    end

    trait :with_pos_e do
      after(:create) do |player|
        create(:player_position, player: player, position: Position.find_by(name: Position::WING_BACK))
      end
    end

    trait :with_pos_c do
      after(:create) do |player|
        create(:player_position, player: player, position: Position.find_by(name: Position::CENTER_MF))
      end
    end

    trait :with_pos_m do
      after(:create) do |player|
        create(:player_position, player: player, position: Position.find_by(name: Position::DEFENCE_MF))
      end
    end

    trait :with_pos_w do
      after(:create) do |player|
        create(:player_position, player: player, position: Position.find_by(name: Position::WINGER))
      end
    end

    trait :with_pos_w_a do
      after(:create) do |player|
        create(:player_position, player: player, position: Position.find_by(name: Position::WINGER))
        create(:player_position, player: player, position: Position.find_by(name: Position::FORWARD))
      end
    end

    trait :with_pos_a do
      after(:create) do |player|
        create(:player_position, player: player, position: Position.find_by(name: Position::FORWARD))
      end
    end

    trait :with_pos_pc do
      after(:create) do |player|
        create(:player_position, player: player, position: Position.find_by(name: Position::STRIKER))
      end
    end
  end
end
