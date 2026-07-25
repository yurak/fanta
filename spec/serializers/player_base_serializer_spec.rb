require 'rails_helper'

RSpec.describe PlayerBaseSerializer do
  describe '#serializable_hash' do
    it 'serializes all fields' do
      serializer = described_class.new(create(:player))

      expect(serializer.serializable_hash.keys).to match_array(expected_keys)
    end
  end

  describe 'season stats' do
    let(:tournament) { create(:tournament) }
    let(:club_a) { create(:club, tournament: tournament) }
    let(:club_b) { create(:club, tournament: tournament) }
    let(:player) { create(:player, club: club_b) }
    let(:season) { Season.last }

    context 'when the player played for two clubs in the season' do
      subject(:hash) { described_class.new(player, season_id: season.id).serializable_hash }

      before do
        create(:player_season_stat, player: player, club: club_a, season: season, tournament: tournament,
                                    played_matches: 10, score: 6.0, final_score: 6.0)
        create(:player_season_stat, player: player, club: club_b, season: season, tournament: tournament,
                                    played_matches: 30, score: 8.0, final_score: 8.0)
      end

      it 'sums appearances across clubs' do
        expect(hash[:appearances]).to eq(40)
      end

      it 'weights the base score by played matches' do
        expect(hash[:average_base_score]).to eq(7.5) # (6*10 + 8*30) / 40
      end

      it 'weights the total score by played matches' do
        expect(hash[:average_total_score]).to eq(7.5) # (6*10 + 8*30) / 40
      end
    end

    context 'with round players across seasons' do
      subject(:hash) { described_class.new(player, season_id: current_season.id).serializable_hash }

      # force `season` (current Season.last) to resolve before a newer season is created
      let!(:older_season) { season }
      let!(:current_season) { create(:season, start_year: 2030, end_year: 2031) }

      before do
        create(:round_player, player: player,
                              tournament_round: create(:tournament_round, season: older_season))
        create_list(:round_player, 3, player: player,
                                      tournament_round: create(:tournament_round, season: current_season))
      end

      it 'counts only the requested season round players' do
        expect(hash[:appearances_max]).to eq(3)
      end
    end

    context 'when a past season is requested' do
      subject(:hash) { described_class.new(player, season_id: past_season.id).serializable_hash }

      let(:past_season) { create(:season, start_year: 2020, end_year: 2021) }

      before do
        past_season
        create(:season, start_year: 2025, end_year: 2026) # newer, becomes Season.last
      end

      it 'hides average_price' do
        expect(hash[:average_price]).to be_nil
      end

      it 'hides teams_count' do
        expect(hash[:teams_count]).to be_nil
      end

      it 'hides teams_count_max' do
        expect(hash[:teams_count_max]).to be_nil
      end
    end
  end

  def expected_keys
    %i[
      id appearances appearances_max avatar_path average_base_score average_price average_total_score club
      first_name league_price league_team_logo leagues name newbie position_classic_arr position_ital_arr stats_price
      teams_count teams_count_max
    ]
  end
end
