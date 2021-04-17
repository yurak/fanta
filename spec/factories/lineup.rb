FactoryBot.define do
  factory :lineup do
    association :team_module
    association :tour
    association :team

    trait :with_match do
      after(:create) do |lineup|
        create(:match, host: lineup.team, tour: lineup.tour)
      end
    end

    trait :with_match_and_opponent_lineup do
      after(:create) do |lineup|
        match = create(:match, host: lineup.team, tour: lineup.tour)
        create(:lineup, :with_team_and_score_six, tour: lineup.tour, team: match.guest)
      end
    end

    trait :with_match_and_opponent_host_lineup do
      after(:create) do |lineup|
        match = create(:match, guest: lineup.team, tour: lineup.tour)
        create(:lineup, :with_team_and_score_six, tour: lineup.tour, team: match.host)
      end
    end

    trait :with_match_players do
      after(:create) do |lineup|
        player_por = create(:round_player, :with_pos_por, tournament_round: lineup.tournament_round)
        create(:match_player, lineup: lineup, round_player: player_por,
                              real_position: player_por.positions.first.name)

        4.times do
          player_dc = create(:round_player, :with_pos_dc, tournament_round: lineup.tournament_round)
          create(:match_player, lineup: lineup, round_player: player_dc,
                                real_position: player_dc.positions.first.name)
        end

        3.times do
          player_c = create(:round_player, :with_pos_c, tournament_round: lineup.tournament_round)
          create(:match_player, lineup: lineup, round_player: player_c,
                                real_position: player_c.positions.first.name)
          player_a = create(:round_player, :with_pos_a, tournament_round: lineup.tournament_round)
          create(:match_player, lineup: lineup, round_player: player_a,
                                real_position: player_a.positions.first.name)
        end

        7.times do
          player_res = create(:round_player, tournament_round: lineup.tournament_round)
          create(:match_player, lineup: lineup, round_player: player_res)
        end

        lineup.reload
      end
    end

    trait :with_team_and_score_five do
      with_match_players
      after(:create) do |lineup|
        lineup.match_players.each do |mp|
          mp.round_player.update(score: 5.0)
        end
      end
    end

    trait :with_team_and_score_six do
      with_match_players
      after(:create) do |lineup|
        lineup.match_players.each do |mp|
          mp.round_player.update(score: 6.0)
        end
      end
    end

    trait :with_team_and_score_seven do
      with_match_players
      after(:create) do |lineup|
        lineup.match_players.each do |mp|
          mp.round_player.update(score: 7.0)
        end
      end
    end

    trait :with_team_and_score_eight do
      with_match_players
      after(:create) do |lineup|
        lineup.match_players.each do |mp|
          mp.round_player.update(score: 8.0)
        end
      end
    end

    trait :league_with_custom_bonus do
      after(:create) do |lineup|
        lineup.team.league.update(min_avg_def_score: 7, max_avg_def_score: 8)
      end
    end
  end
end
